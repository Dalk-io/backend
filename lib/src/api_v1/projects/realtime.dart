import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:backend/src/models/conversation.dart';
import 'package:backend/src/models/message.dart';
import 'package:backend/src/models/project.dart';
import 'package:backend/src/models/user.dart';
import 'package:backend/src/rpc/conversation/get_conversation_by_id.dart';
import 'package:backend/src/rpc/conversation/get_number_of_message_for_conversation.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:backend/src/rpc/conversation/save_conversation.dart';
import 'package:backend/src/rpc/conversation/update_conversation_last_update.dart';
import 'package:backend/src/rpc/conversation/update_conversation_subject_and_avatar.dart';
import 'package:backend/src/rpc/conversations/get_conversations_for_user.dart';
import 'package:backend/src/rpc/conversations/parameters.dart';
import 'package:backend/src/rpc/message/get_message_by_id.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:backend/src/rpc/message/save_message.dart';
import 'package:backend/src/rpc/message/update_message_state.dart';
import 'package:backend/src/rpc/messages/get_messages_for_conversation.dart';
import 'package:backend/src/rpc/messages/parameters.dart';
import 'package:http/io_client.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

typedef DateTimeFactory = DateTime Function();

DateTime _defaultDateTimeFactory() => DateTime.now().toUtc();

@immutable
class Realtime {
  final Project project;
  final UpdateConversationSubjectAndAvatar _updateConversationSubjectAndAvatar;
  final GetConversationById _getConversationById;
  final SaveConversation _saveConversation;
  final GetConversationsForUser _getConversationsForUser;
  final GetMessagesForConversation _getMessagesForConversation;
  final UpdateConversationLastUpdate _updateConversationLastUpdate;
  final GetNumberOfMessageForConversation _getNumberOfMessageForConversation;
  final SaveMessage _saveMessage;
  final GetMessageById _getMessageById;
  final UpdateMessageState _updateMessageState;

  final List<String> _users = [];
  final List<Peer> _connectedPeers = [];
  final List<User> _connectedUsers = [];
  final DateTimeFactory _dateTimeFactory;

  final Logger _logger;
  final IOClient _httpClient;

  Realtime(
    this.project,
    this._updateConversationSubjectAndAvatar,
    this._getConversationById,
    this._saveConversation,
    this._updateConversationLastUpdate,
    this._getNumberOfMessageForConversation,
    this._getConversationsForUser,
    this._saveMessage,
    this._getMessageById,
    this._updateMessageState,
    this._getMessagesForConversation, {
    DateTimeFactory dateTimeFactory,
    IOClient httpClient,
  })  : _logger = Logger('Realtime-${project.id}'),
        _httpClient = httpClient ?? IOClient(),
        _dateTimeFactory = dateTimeFactory ?? _defaultDateTimeFactory;

  List<Peer> get connectedPeers => _connectedPeers;

  @visibleForTesting
  List<User> get connectedUsers => _connectedUsers;

  void addPeer(Peer peer) {
    final logger = Logger('${_logger.name}.addPeer');
    logger.info('add Peer');
    _connectedPeers.add(peer);

    peer.registerMethod('registerUser', (Parameters parameters) => registerUser(parameters, peer));

    peer.registerMethod('getConversations', () => getConversations(peer));

    peer.registerMethod('setConversationOptions', (Parameters parameters) => setConversationOptions(parameters, peer));

    peer.registerMethod('getOrCreateConversation', (Parameters parameters) => getOrCreateConversation(parameters, peer));

    peer.registerMethod('getMessages', (Parameters parameters) => getMessages(parameters));

    peer.registerMethod('getConversationDetail', (Parameters parameters) => getConversationDetail(parameters));

    peer.registerMethod('sendMessage', (Parameters parameters) => sendMessage(parameters, peer));

    peer.registerMethod('updateMessageState', (Parameters parameters) => updateMessageState(parameters, peer));

    peer.registerFallback((parameters) => throw RpcException.methodNotFound(parameters.method));
  }

  void removePeer(Peer peer) {
    final logger = Logger('${_logger.name}.addPeer');
    logger.info('remove Peer');
    _connectedUsers.removeWhere((element) => element.peer == peer);
    _connectedPeers.remove(peer);
  }

  bool registerUser(Parameters parameters, Peer peer) {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.registerUser');
    final id = parameters['id'].asString;
    logger.fine('register user $id');
    _connectedUsers.add(User(id, peer));
    _users.add(id);
    logger.info('registerUser took ${sw.elapsed}');
    return true;
  }

  Future<void> setConversationOptions(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.setConversationOptions');
    final conversationId = parameters['conversationId'].asString;
    final subject = parameters['subject'].asStringOr(null);
    final avatar = parameters['avatar'].asStringOr(null);
    logger.fine('set conversation options subject: $subject, avatar: $avatar');
    final conversation = _getConversationById.request(GetConversationByIdParameters(project.id, conversationId, false));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('setConversationOptions took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    await _updateConversationSubjectAndAvatar.request(UpdateConversationSubjectAndAvatarParameters(project.id, conversationId, subject, avatar));
    logger.info('setConversationOptions took ${sw.elapsed}');
  }

  Future<List<Map<String, dynamic>>> getConversations(Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.getConversations');
    logger.fine('get conversations');
    final user = _connectedUsers.firstWhere(
      (element) => element.peer == peer,
      orElse: () => null,
    );
    final userConversations = await _getConversationsForUser.request(GetConversationsForUserParameters(project.id, user.id));
    final response = userConversations.map((conversation) => conversation.toJson(putMessages: true)).toList(growable: false);
    logger.info('getConversations took ${sw.elapsed}');
    return response;
  }

  Future<Map<String, dynamic>> getOrCreateConversation(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.getOrcreateConversation');
    final conversationId = parameters['id'].asString;
    final user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    final existingConversation = await _getConversationById.request(GetConversationByIdParameters(project.id, conversationId, false));
    if (existingConversation != null) {
      logger.fine('get conversations ${existingConversation.id} ${existingConversation.users} ${existingConversation.subject} ${existingConversation.avatar}');
      logger.info('getOrcreateConversation took ${sw.elapsed}');
      return existingConversation.toJson();
    }
    final to = parameters['users'].asList.cast<String>()..removeWhere((element) => element == user.id);
    final subject = parameters['subject'].asStringOr(null);
    final avatar = parameters['avatar'].asStringOr(null);
    final isGroup = parameters['isGroupd'].asBoolOr(false);
    final conversation = Conversation(
      conversationId,
      subject,
      avatar,
      {user.id},
      {
        user.id,
        ...to,
      },
      isGroup,
    );
    logger.fine('create conversations $conversation');
    await _saveConversation.request(SaveConversationParameters(project.id, conversation));
    final connectedOthers = [
      ..._connectedUsers.where((element) => to.contains(element.id)),
      ..._connectedUsers.where((element) => element.id == user.id).where((element) => element.peer != user.peer)
    ];
    final response = conversation.toJson(putMessages: true);
    if (to.length > 1) {
      for (final other in connectedOthers) {
        logger.fine('on conversation created ${other.id} $conversation');
        other.onConversationCreated(response);
      }
    }
    logger.info('getOrcreateConversation took ${sw.elapsed}');
    return response;
  }

  Future<List<Map<String, dynamic>>> getMessages(Parameters parameters) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.getMessages');
    final from = parameters['from'].asIntOr(0);
    final to = parameters['to'].asIntOr(-1);
    final conversationId = parameters['conversationId'].asString;
    logger.fine('get messages parameters $from $to');
    if (to != -1 && from > to) {
      throw RpcException.invalidParams('from can\'t be inferior at to');
    }
    final conversation = _getConversationById.request(GetConversationByIdParameters(project.id, conversationId, false));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('getMessages took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    var messages = await _getMessagesForConversation.request(GetMessagesForConversationParameters(project.id, conversationId, from, to));
    if (messages.length > from) {
      messages = messages.skip(from).toList();
    }
    if (to != -1 && messages.length >= to - from) {
      messages = messages.take(to - from).toList();
    }
    final response = messages.map((message) => message.toJson()).toList(growable: false);
    logger.info('getMessages took ${sw.elapsed}');
    return response;
  }

  Future<Map<String, dynamic>> getConversationDetail(Parameters parameters) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.getConversationDetail');
    final conversationId = parameters['id'].asString;
    logger.fine('get conversation parameters $conversationId');
    final conversation = await _getConversationById.request(GetConversationByIdParameters(project.id, conversationId, true));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('getConversationDetail took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    final response = conversation?.toJson(putMessages: true);
    logger.info('getConversationDetail took ${sw.elapsed}');
    return response;
  }

  Future<Map<String, dynamic>> sendMessage(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.sendMessage');
    final conversationId = parameters['conversationId'].asString;
    final text = parameters['text'].asStringOr(null);
    logger.fine('send message parameters $conversationId $text');
    final conversation = await _getConversationById.request(GetConversationByIdParameters(project.id, conversationId, false));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('sendMessage took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    final user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    final others = conversation.users.where((element) => element != user.id).toList();
    final messageState = [
      MessageStateByUser(user.id, MessageState.seen),
      ...others.map((value) => MessageStateByUser(value, MessageState.sent)),
    ];
    final numberOfMessage = await _getNumberOfMessageForConversation.request(GetNumberOfMessageForConversationParameter(project.id, conversationId));
    final messageId = await _saveMessage.request(SaveMessageParameters(project.id, conversationId, user.id, text, messageState));
    final message = Message(project.id, '$messageId', conversationId, user.id, text, _dateTimeFactory(), messageState);
    logger.fine('send message $message');
    final connectedOthers = [
      ..._connectedUsers.where((element) => others.contains(element.id)),
      ..._connectedUsers.where((element) => element.id == user.id).where((element) => element.peer != user.peer)
    ];
    await _updateConversationLastUpdate.request(UpdateConversationLastUpdateParameters(project.id, conversationId));
    conversation.messages.add(message);
    var createConversation = false;
    if (numberOfMessage == 0 && others.length == 1 && connectedOthers.isNotEmpty) {
      for (final otherUsers in connectedOthers) {
        logger.fine('created conversation $conversation for user ${otherUsers.id}');
        otherUsers.onConversationCreated(conversation.toJson(putMessages: true));
      }
      createConversation = true;
    }
    final messageJson = message.toJson();
    if (!createConversation) {
      for (final other in connectedOthers) {
        logger.fine('send message to user ${other.id}');
        other.receiveMessage(conversation.id, messageJson);
      }
    }
    if (project.webhook != null) {
      runZoned(
        () {
          _httpClient.post(project.webhook, body: json.encode(messageJson));
        },
        zoneSpecification: ZoneSpecification(handleUncaughtError: (_, __, ___, ____, _____) {
          logger.warning('${project.webhook} is failing');
        }),
      );
    }
    logger.info('sendMessage took ${sw.elapsed}');
    return messageJson;
  }

  Future<void> updateMessageState(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.updateMessageState');
    final messageId = int.parse(parameters['id'].asString);
    final stateData = parameters['state'].asInt;
    logger.fine('update message state parameters $messageId $stateData');
    var message = await _getMessageById.request(GetMessageByIdParameters(project.id, messageId));
    if (message == null) {
      logger.warning('Message $messageId not found');
      logger.info('sendMessage took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Message not found', data: {'id': messageId});
    }
    final user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    final oldUserMessageState = message.states.firstWhere((state) => state.id == user.id, orElse: () => null);
    if (oldUserMessageState.state.index > stateData) {
      throw RpcException(HttpStatus.preconditionFailed, 'Cannot change state', data: {'oldState': oldUserMessageState.state.index, 'newState': stateData});
    }
    if (oldUserMessageState.state.index == stateData) {
      return;
    }
    final userMessageState = MessageStateByUser(user.id, MessageState.values[stateData]);
    final newStates = [
      ...message.states.where((state) => state.id != user.id),
      userMessageState,
    ];
    logger.fine('new states $newStates');
    message = await _updateMessageState.request(UpdateMessageStateParameters(project.id, message.conversationId, messageId, newStates));
    final conversation = await _getConversationById.request(GetConversationByIdParameters(project.id, message.conversationId, false));
    final others = conversation.users.where((element) => element != user.id).toList();
    final connectedOthers = [
      ..._connectedUsers.where((element) => others.contains(element.id)),
      ..._connectedUsers.where((element) => element.id == user.id).where((element) => element.peer != user.peer)
    ];
    for (final other in connectedOthers) {
      logger.info('update message state $message');
      other.updateMessageState(message.conversationId, message.toJson());
    }
    logger.info('sendMessage took ${sw.elapsed}');
  }
}
