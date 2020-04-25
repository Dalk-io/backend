import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:backend/backend.dart';
import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/data/user/user.dart';
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
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:crypto/crypto.dart';
import 'package:http/io_client.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

typedef DateTimeFactory = DateTime Function();
typedef MessageIdFactory = String Function();

DateTime _defaultDateTimeFactory() => DateTime.now().toUtc();
String _defaultMessageIdFactory() {
  final uuid = Uuid(options: <String, dynamic>{'grng': UuidUtil.cryptoRNG});
  return uuid.v4();
}

@immutable
class Realtime {
  final String projectKey;
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
  final GetProjectByKey _getProjectByKey;
  final UserRpcs _userRpcs;

  final List<Peer> _connectedPeers = [];
  final List<User> _connectedUsers = [];
  final DateTimeFactory _dateTimeFactory;

  final Logger _logger;
  final IOClient _httpClient;
  final MessageIdFactory _messageIdFactory;

  Realtime(
    this.projectKey,
    this._updateConversationSubjectAndAvatar,
    this._getConversationById,
    this._saveConversation,
    this._updateConversationLastUpdate,
    this._getNumberOfMessageForConversation,
    this._getConversationsForUser,
    this._saveMessage,
    this._getMessageById,
    this._updateMessageState,
    this._getMessagesForConversation,
    this._getProjectByKey,
    this._userRpcs, {
    DateTimeFactory dateTimeFactory,
    IOClient httpClient,
    MessageIdFactory messageIdFactory,
  })  : _logger = Logger('Realtime-${projectKey}'),
        _httpClient = httpClient ?? IOClient(),
        _dateTimeFactory = dateTimeFactory ?? _defaultDateTimeFactory,
        _messageIdFactory = messageIdFactory ?? _defaultMessageIdFactory;

  @visibleForTesting
  List<User> get connectedUsers => _connectedUsers;

  @visibleForTesting
  IOClient get httpClient => _httpClient;

  List<Peer> get connectedPeers => _connectedPeers;

  void addPeer(Peer peer) {
    final logger = Logger('${_logger.name}.addPeer');
    logger.info('add Peer');
    _connectedPeers.add(peer);

    peer.registerMethod('registerUser', (Parameters parameters) => registerUser(parameters, peer));

    peer.registerMethod('getConversations', () => getConversations(peer));

    peer.registerMethod('setConversationOptions', (Parameters parameters) => setConversationOptions(parameters, peer));

    peer.registerMethod('getOrCreateConversation', (Parameters parameters) => getOrCreateConversation(parameters, peer));

    peer.registerMethod('getMessages', (Parameters parameters) => getMessages(parameters, peer));

    peer.registerMethod('getConversationDetail', (Parameters parameters) => getConversationDetail(parameters, peer));

    peer.registerMethod('sendMessage', (Parameters parameters) => sendMessage(parameters, peer));

    peer.registerMethod('updateMessageState', (Parameters parameters) => updateMessageState(parameters, peer));

    peer.registerFallback((parameters) => throw RpcException.methodNotFound(parameters.method));
  }

  Future<void> removePeer(Peer peer) async {
    final logger = Logger('${_logger.name}.addPeer');
    logger.info('remove Peer');
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user != null) {
      final user = await _userRpcs.getUserById.request(GetUserByIdParameters(projectKey, _user.data.id));
      await _userRpcs.updateUserById.request(UpdateUserParameters(projectKey, user.id, user.name, user.avatar, UserState.offline));
    }
    _connectedUsers.removeWhere((element) => element.peer == peer);
    _connectedPeers.remove(peer);
  }

  Future<void> registerUser(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.registerUser');
    final id = parameters['id'].asString;
    final signature = parameters['signature'].asStringOr(null);
    final name = parameters['name'].asStringOr(null);
    final avatar = parameters['avatar'].asStringOr(null);
    final project = await _getProjectByKey.request(projectKey);
    final environment = projectKey == project.production?.key ? project.production : project.development;
    if (project.isSecure) {
      final _signature = sha512.convert(utf8.encode('$id${environment.secret}')).toString();
      if (signature != _signature) {
        logger.warning('signature not valid received ${signature} but waiting ${_signature}');
        throw RpcException(HttpStatus.unauthorized, 'Invalid signature');
      }
    }
    logger.fine('register user $id');
    final user = await _userRpcs.getUserById.request(GetUserByIdParameters(projectKey, id));
    if (user == null) {
      await _userRpcs.saveUser.request(SaveUserParameters(projectKey, id, name, avatar, UserState.online));
    } else {
      await _userRpcs.updateUserById.request(UpdateUserParameters(projectKey, user.id, user.name, user.avatar, UserState.online));
    }
    _connectedUsers.add(User(peer, UserData(id, name: name, avatar: avatar)));
    logger.info('registerUser took ${sw.elapsed}');
  }

  Future<void> setConversationOptions(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.setConversationOptions');
    final conversationId = parameters['conversationId'].asString;
    final subject = parameters['subject'].asStringOr(null);
    final avatar = parameters['avatar'].asStringOr(null);
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user == null) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    logger.fine('set conversation options subject: $subject, avatar: $avatar');
    final conversation = _getConversationById.request(GetConversationByIdParameters(projectKey, conversationId));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('setConversationOptions took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    await _updateConversationSubjectAndAvatar
        .request(UpdateConversationSubjectAndAvatarParameters(projectKey, conversationId, subject: subject, avatar: avatar));
    logger.info('setConversationOptions took ${sw.elapsed}');
  }

  Future<List<Map<String, dynamic>>> getConversations(Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.getConversations');
    logger.fine('get conversations');
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user == null) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    final userConversations = await _getConversationsForUser.request(GetConversationsForUserParameters(projectKey, _user.data.id));
    final response = userConversations.map((conversation) {
      final conversationJson = conversation.toJson();
      conversationJson['messages'] = [_messageToJson(conversation.messages.first)];
      return conversationJson;
    }).toList(growable: false);
    logger.info('getConversations took ${sw.elapsed}');
    return response;
  }

  Future<Map<String, dynamic>> getOrCreateConversation(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.getOrCreateConversation');
    final conversationId = parameters['id'].asString;
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user == null) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    final user = await _userRpcs.getUserById.request(GetUserByIdParameters(projectKey, _user.data.id));
    final existingConversation = await _getConversationById.request(GetConversationByIdParameters(projectKey, conversationId));
    if (existingConversation != null) {
      logger.fine('get conversations ${existingConversation.id} ${existingConversation.users} ${existingConversation.subject} ${existingConversation.avatar}');
      logger.info('getOrCreateConversation took ${sw.elapsed}');
      return existingConversation.toJson();
    }
    final _to = parameters['users']
        .asList
        .cast<Map>()
        .cast<Map<String, dynamic>>()
        .map<UserData>((user) => UserData(user['id'] as String, name: user['name'] as String, avatar: user['avatar'] as String))
        .where((to) => to.id != _user.data.id);
    final to = <UserData>[];
    for (final t in _to) {
      final u = await _userRpcs.getUserById.request(GetUserByIdParameters(projectKey, t.id));
      if (u != null) {
        to.add(u);
      } else {
        await _userRpcs.saveUser.request(SaveUserParameters(projectKey, t.id, t.name, t.avatar, UserState.offline));
        to.add(t);
      }
    }
    final project = await _getProjectByKey.request(projectKey);
    if (project.groupLimitation != -1 && to.length + 1 > project.groupLimitation) {
      throw RpcException(
        HttpStatus.unauthorized,
        'Group conversation limit',
        data: {'groupLimitation': project.groupLimitation, 'groupSize': to.length},
      );
    }
    final subject = parameters['subject'].asStringOr(null);
    final avatar = parameters['avatar'].asStringOr(null);
    final isGroup = parameters['isGroup'].asBoolOr(false);
    final conversation = ConversationData(
      id: conversationId,
      subject: subject,
      avatar: avatar,
      admins: [_user.data],
      users: [
        _user.data,
        ...to,
      ],
      isGroup: isGroup,
    );
    logger.fine('create conversations $conversation');
    await _saveConversation.request(SaveConversationParameters(projectKey, conversation));
    final connectedOthers = [
      ..._connectedUsers.where((element) => to.contains(element.data)),
      ..._connectedUsers.where((element) => element.data.id == user.id).where((element) => element.peer != _user.peer)
    ];
    final response = conversation.toJson();
    if (to.length > 1) {
      for (final other in connectedOthers) {
        logger.fine('on conversation created ${other.data.id} $conversation');
        other.onConversationCreated(response);
      }
    }
    logger.info('getOrCreateConversation took ${sw.elapsed}');
    return response;
  }

  Future<List<Map<String, dynamic>>> getMessages(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.getMessages');
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user == null) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    final from = parameters['from'].asIntOr(0);
    final to = parameters['to'].asIntOr(-1);
    final conversationId = parameters['conversationId'].asString;
    logger.fine('get messages parameters $from $to');
    if (to != -1 && from > to) {
      throw RpcException.invalidParams('from can\'t be inferior at to');
    }
    final conversation = _getConversationById.request(GetConversationByIdParameters(projectKey, conversationId));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('getMessages took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    var messages = await _getMessagesForConversation.request(GetMessagesForConversationParameters(projectKey, conversationId, from: from, to: to));
    if (messages.length > from) {
      messages = messages.skip(from).toList();
    }
    if (to != -1 && messages.length >= to - from) {
      messages = messages.take(to - from).toList();
    }
    final response = messages.map(_messageToJson).toList(growable: false);
    logger.info('getMessages took ${sw.elapsed}');
    return response;
  }

  Future<Map<String, dynamic>> getConversationDetail(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.getConversationDetail');
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user == null) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    final conversationId = parameters['id'].asString;
    logger.fine('get conversation parameters $conversationId');
    final conversation = await _getConversationById.request(GetConversationByIdParameters(projectKey, conversationId, getMessages: true));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('getConversationDetail took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    final response = conversation?.toJson();
    logger.info('getConversationDetail took ${sw.elapsed}');
    return response;
  }

  Future<Map<String, dynamic>> sendMessage(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.sendMessage');
    final conversationId = parameters['conversationId'].asString;
    final text = parameters['text'].asStringOr(null);
    logger.fine('send message parameters $conversationId $text');
    final conversation = await _getConversationById.request(GetConversationByIdParameters(projectKey, conversationId));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('sendMessage took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user == null) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    final others = conversation.users.where((user) => user.id != _user.data.id);
    final messageState = <MessageStateByUserData>[
      MessageStateByUserData(_user.data.id, MessageState.seen),
      ...others.map((value) => MessageStateByUserData(value.id, MessageState.sent)),
    ];
    final numberOfMessage = await _getNumberOfMessageForConversation.request(GetNumberOfMessageForConversationParameter(projectKey, conversationId));
    final id = _messageIdFactory();
    await _saveMessage.request(SaveMessageParameters(id, projectKey, conversationId, _user.data.id, text, messageState));
    final message = MessageData(id, projectKey, conversationId, _user.data.id, text, _dateTimeFactory(), messageState);
    logger.fine('send message $message');
    final connectedOthers = [
      ..._connectedUsers.where((element) => others.contains(element.data)),
      ..._connectedUsers.where((element) => element.data.id == _user.data.id).where((element) => element.peer != _user.peer)
    ];
    await _updateConversationLastUpdate.request(UpdateConversationLastUpdateParameters(projectKey, conversationId));
    final newConversation = conversation.copyWith(messages: [message]);
    var createConversation = false;
    if (numberOfMessage == 0 && others.length == 1 && connectedOthers.isNotEmpty) {
      for (final otherUsers in connectedOthers) {
        logger.fine('created conversation $conversation for user ${otherUsers.data.id}');
        otherUsers.onConversationCreated(newConversation.toJson());
      }
      createConversation = true;
    }
    final messageJson = _messageToJson(message);
    if (!createConversation) {
      for (final other in connectedOthers) {
        logger.fine('send message to user ${other.data.id}');
        other.receiveMessage(conversation.id, messageJson);
      }
    }
    final project = await _getProjectByKey.request(projectKey);
    final _projectInformation = projectKey == project.production?.key ? project.production : project.development;
    if (_projectInformation.webHook != null) {
      runZoned(
        () {
          _httpClient.post(_projectInformation.webHook, body: json.encode(messageJson));
        },
        zoneSpecification: ZoneSpecification(handleUncaughtError: (_, __, ___, ____, _____) {
          logger.warning('${_projectInformation.webHook} is failing');
        }),
      );
    }
    logger.info('sendMessage took ${sw.elapsed}');
    return messageJson;
  }

  Future<void> updateMessageState(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.updateMessageState');
    final messageId = parameters['id'].asString;
    final stateData = messageStateFromString(parameters['state'].asString);
    logger.fine('update message state parameters $messageId $stateData');
    var message = await _getMessageById.request(GetMessageByIdParameters(projectKey, messageId));
    if (message == null) {
      logger.warning('Message $messageId not found');
      logger.info('updateMessageState took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Message not found', data: {'id': messageId});
    }
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user == null || !message.states.map((state) => state.id).contains(_user.data.id)) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    final oldUserMessageState = message.states.firstWhere((state) => state.id == _user.data.id, orElse: () => null);
    if (oldUserMessageState.state.index >= stateData.index) {
      logger.warning('same state, nothing to do');
      return;
    }
    final userMessageState = MessageStateByUserData(_user.data.id, stateData);
    final newStates = <MessageStateByUserData>[
      ...message.states.where((state) => state.id != _user.data.id),
      userMessageState,
    ];
    logger.fine('new states $newStates');
    message = await _updateMessageState.request(UpdateMessageStateParameters(projectKey, message.conversationId, messageId, newStates));
    print(message);
    final conversation = await _getConversationById.request(GetConversationByIdParameters(projectKey, message.conversationId));
    final others = _connectedUsers.where((user) => conversation.users.contains(user.data)).where((user) => user.data.id != _user.data.id);
    final connectedOthers = [
      ...others,
      ..._connectedUsers.where((element) => element.data.id == _user.data.id).where((element) => element.peer != _user.peer),
    ];
    for (final other in connectedOthers) {
      logger.info('update message state $message');
      other.updateMessageState(message.conversationId, _messageToJson(message));
    }
    logger.info('updateMessageState took ${sw.elapsed}');
  }

  Map<String, dynamic> _messageToJson(MessageData message) {
    return <String, dynamic>{
      ...message.toJson(),
      'state': computeMessageState(message),
      'states': computeMessageStates(message),
    }
      ..remove('projectId')
      ..remove('conversationId');
  }
}
