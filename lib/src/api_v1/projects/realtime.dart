import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:backend/backend.dart';
import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/data/project/project.dart';
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
import 'package:backend/src/rpc/message/update_message_status.dart';
import 'package:backend/src/rpc/messages/get_messages_for_conversation.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:backend/src/utils/get_group_limitation_from_subscription.dart';
import 'package:backend/src/utils/message_to_json.dart';
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
  final UpdateConversationSubjectAndAvatar updateConversationSubjectAndAvatar;
  final GetConversationById getConversationById;
  final SaveConversation saveConversation;
  final GetConversationsForUser getConversationsForUser;
  final GetMessagesForConversation getMessagesForConversation;
  final UpdateConversationLastUpdate updateConversationLastUpdate;
  final GetNumberOfMessageForConversation getNumberOfMessageForConversation;
  final SaveMessage saveMessage;
  final GetMessageById getMessageById;
  final UpdateMessageStatus updateMessageStatusRpc;
  final UpdateMessage updateMessageRpc;
  final GetProjectByKey getProjectByKey;
  final UserRpcs userRpcs;

  final List<Peer> _connectedPeers = [];
  final List<User> _connectedUsers = [];
  final DateTimeFactory _dateTimeFactory;

  final Logger _logger;
  final IOClient _httpClient;
  final MessageIdFactory _messageIdFactory;

  Realtime(
    this.projectKey,
    this.updateConversationSubjectAndAvatar,
    this.getConversationById,
    this.saveConversation,
    this.updateConversationLastUpdate,
    this.getNumberOfMessageForConversation,
    this.getConversationsForUser,
    this.saveMessage,
    this.getMessageById,
    this.updateMessageStatusRpc,
    this.getMessagesForConversation,
    this.getProjectByKey,
    this.userRpcs,
    this.updateMessageRpc, {
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

    peer.registerMethod('updateMessageStatus', (Parameters parameters) => updateMessageStatus(parameters, peer));

    peer.registerMethod('updateMessage', (Parameters parameters) => updateMessage(parameters, peer));

    peer.registerFallback((parameters) => throw RpcException.methodNotFound(parameters.method));
  }

  Future<void> removePeer(Peer peer) async {
    final logger = Logger('${_logger.name}.addPeer');
    logger.info('remove Peer');
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user != null) {
      final user = await userRpcs.getUserById.request(GetUserByIdParameters(projectKey, _user.data.id));
      await userRpcs.updateUserById.request(UpdateUserParameters(projectKey, user.id, user.name, user.avatar, UserState.offline));
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
    final project = await getProjectByKey.request(projectKey);
    final environment = projectKey == project.production?.key ? project.production : project.development;
    if (environment.isSecure) {
      final _signature = sha512.convert(utf8.encode('$id${environment.secret}')).toString();
      if (signature != _signature) {
        logger.warning('signature not valid received ${signature} but waiting ${_signature}');
        throw RpcException(HttpStatus.unauthorized, 'Invalid signature');
      }
    }
    logger.fine('register user $id');
    final user = await userRpcs.getUserById.request(GetUserByIdParameters(projectKey, id));
    if (user == null) {
      await userRpcs.saveUser.request(SaveUserParameters(projectKey, id, name, avatar, UserState.online));
    } else {
      await userRpcs.updateUserById.request(UpdateUserParameters(projectKey, user.id, user.name, user.avatar, UserState.online));
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
    final conversation = await getConversationById.request(GetConversationByIdParameters(projectKey, conversationId));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('setConversationOptions took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    if (!conversation.admins.contains(_user.data)) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    await updateConversationSubjectAndAvatar
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
    final userConversations = await getConversationsForUser.request(GetConversationsForUserParameters(projectKey, _user.data.id));
    final response = userConversations
        .where((conversation) => conversation.isGroup || conversation.messages.isNotEmpty || conversation.admins.contains(_user.data))
        .map((conversation) {
      final conversationJson = conversation.toJson();
      conversationJson['messages'] = [if (conversation.messages.isNotEmpty) messageToJson(conversation.messages.first)];
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
    final user = await userRpcs.getUserById.request(GetUserByIdParameters(projectKey, _user.data.id));
    final existingConversation = await getConversationById.request(GetConversationByIdParameters(projectKey, conversationId));
    if (existingConversation != null) {
      if (!existingConversation.users.contains(user)) {
        throw RpcException(HttpStatus.unauthorized, 'Not authorized');
      }
      logger.fine('get conversations ${existingConversation.id} ${existingConversation.users} ${existingConversation.subject} ${existingConversation.avatar}');
      logger.info('getOrCreateConversation took ${sw.elapsed}');
      final response = existingConversation.toJson();
      response['messages'] = existingConversation.messages.map(messageToJson).toList();
      return response;
    }
    final _to = parameters['users']
        .asList
        .cast<Map>()
        .cast<Map<String, dynamic>>()
        .map<UserData>((user) => UserData(user['id'] as String, name: user['name'] as String, avatar: user['avatar'] as String))
        .where((to) => to.id != _user.data.id)
        .toSet();
    final to = <UserData>[];
    for (final t in _to) {
      final u = await userRpcs.getUserById.request(GetUserByIdParameters(projectKey, t.id));
      if (u != null) {
        to.add(u);
      } else {
        await userRpcs.saveUser.request(SaveUserParameters(projectKey, t.id, t.name, t.avatar, UserState.offline));
        to.add(t);
      }
    }
    final project = await getProjectByKey.request(projectKey);
    final isDevelopment = project.development.key == projectKey;
    final groupLimitation = groupLimitationFromSubscription(project.subscriptionType);
    final exceedGroupLimitation = groupLimitation < to.length;
    if (!isDevelopment && exceedGroupLimitation) {
      throw RpcException(
        HttpStatus.unauthorized,
        'Group conversation limit',
        data: {'groupLimitation': groupLimitation, 'groupSize': to.length},
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
    await saveConversation.request(SaveConversationParameters(projectKey, conversation));
    final connectedOthers = [
      ..._connectedUsers.where((element) => to.contains(element.data)),
      ..._connectedUsers.where((element) => element.data.id == user.id).where((element) => element.peer != _user.peer)
    ];
    final response = conversation.toJson();
    response['messages'] = conversation.messages.map((message) => messageToJson(message)).toList();
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
    if (to != -1 && from < to) {
      throw RpcException.invalidParams('to can\'t be inferior at from');
    }
    final conversation = await getConversationById.request(GetConversationByIdParameters(projectKey, conversationId, from: from, to: to));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('getMessages took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    if (!conversation.users.contains(_user.data)) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    final response = conversation.messages.map(messageToJson).toList(growable: false);
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
    final conversation = await getConversationById.request(GetConversationByIdParameters(projectKey, conversationId));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('getConversationDetail took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    if (!conversation.users.contains(_user.data)) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }

    final response = conversation?.toJson();
    response['messages'] = conversation.messages.map((message) => messageToJson(message)).toList();
    logger.info('getConversationDetail took ${sw.elapsed}');
    return response;
  }

  Future<Map<String, dynamic>> sendMessage(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.sendMessage');
    final conversationId = parameters['conversationId'].asString;
    final text = parameters['text'].asStringOr(null);
    final dynamic metadata = parameters['metadata'].valueOr(null);
    logger.fine('send message parameters $conversationId $text');
    if (metadata != null) {
      final metadataSize = utf8.encode(json.encode(metadata)).length;
      if (metadataSize > 5000) {
        throw RpcException(HttpStatus.badRequest, 'Metadata is too big', data: {
          'maxSize': 5000,
          'currentSize': metadataSize,
        });
      }
    }
    final conversation = await getConversationById.request(GetConversationByIdParameters(projectKey, conversationId));
    if (conversation == null) {
      logger.warning('Conversation $conversationId not found');
      logger.info('sendMessage took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': conversationId});
    }
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user == null) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    if (!conversation.users.contains(_user.data)) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    final others = conversation.users.where((user) => user.id != _user.data.id);
    final messageStatus = <MessageStatusByUserData>[
      MessageStatusByUserData(_user.data.id, MessageStatus.seen),
      ...others.map((value) => MessageStatusByUserData(value.id, MessageStatus.sent)),
    ];
    final numberOfMessage = await getNumberOfMessageForConversation.request(GetNumberOfMessageForConversationParameter(projectKey, conversationId));
    final id = _messageIdFactory();
    await saveMessage.request(SaveMessageParameters(id, projectKey, conversationId, _user.data.id, text, messageStatus, metadata));
    final message = MessageData(id, projectKey, conversationId, _user.data.id, text, _dateTimeFactory(), messageStatus, metadata: metadata);
    logger.fine('send message $message');
    final connectedOthers = [
      ..._connectedUsers.where((element) => others.contains(element.data)),
      ..._connectedUsers.where((element) => element.data.id == _user.data.id).where((element) => element.peer != _user.peer)
    ];
    await updateConversationLastUpdate.request(UpdateConversationLastUpdateParameters(projectKey, conversationId));
    final newConversation = conversation.copyWith(messages: [message]);
    var createConversation = false;
    if (numberOfMessage == 0 && others.length == 1 && connectedOthers.isNotEmpty) {
      for (final otherUsers in connectedOthers) {
        logger.fine('created conversation $conversation for user ${otherUsers.data.id}');
        otherUsers.onConversationCreated(newConversation.toJson());
      }
      createConversation = true;
    }
    final messageJson = messageToJson(message);
    if (!createConversation) {
      for (final other in connectedOthers) {
        logger.fine('send message to user ${other.data.id}');
        other.receiveMessage(conversation.id, messageJson);
      }
    }
    final project = await getProjectByKey.request(projectKey);
    final _projectInformation = projectKey == project.production?.key ? project.production : project.development;
    final isDevelopment = projectKey == project.development.key;
    final canUseWebHook = project.subscriptionType == SubscriptionType.complete;
    final otherUsersInConversation = conversation.users.where((user) => user != _user.data);
    final oneMemberIsNotConnected = connectedOthers.map((all) => all.data).toSet().length < otherUsersInConversation.length;
    print(isDevelopment);
    print(_projectInformation.webHook != null);
    print(oneMemberIsNotConnected);
    if ((isDevelopment || canUseWebHook) && _projectInformation.webHook != null && oneMemberIsNotConnected) {
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

  Future<void> updateMessageStatus(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.updateMessageStatus');
    final messageId = parameters['id'].asString;
    final statusData = messageStatusFromString(parameters['status'].asString);
    logger.fine('update message status parameters $messageId $statusData');
    var message = await getMessageById.request(GetMessageByIdParameters(projectKey, messageId));
    if (message == null) {
      logger.warning('Message $messageId not found');
      logger.info('updateMessageStatus took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Message not found', data: {'id': messageId});
    }
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user == null || !message.statusDetails.map((status) => status.id).contains(_user.data.id)) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    final oldUserMessageStatus = message.statusDetails.firstWhere((status) => status.id == _user.data.id, orElse: () => null);
    if (oldUserMessageStatus.status.index >= statusData.index) {
      logger.warning('same status, nothing to do');
      return;
    }
    final userMessageStatus = MessageStatusByUserData(_user.data.id, statusData);
    final newStatusDetails = <MessageStatusByUserData>[
      ...message.statusDetails.where((status) => status.id != _user.data.id),
      userMessageStatus,
    ];
    logger.fine('new status $newStatusDetails');
    message = await updateMessageStatusRpc.request(UpdateMessageStatusParameters(projectKey, message.conversationId, message.id, newStatusDetails));
    final conversation = await getConversationById.request(GetConversationByIdParameters(projectKey, message.conversationId));
    final others = _connectedUsers.where((user) => conversation.users.contains(user.data)).where((user) => user.data.id != _user.data.id);
    final connectedOthers = [
      ...others,
      ..._connectedUsers.where((element) => element.data.id == _user.data.id).where((element) => element.peer != _user.peer),
    ];
    for (final other in connectedOthers) {
      logger.info('update message status $message');
      other.updateMessageStatus(message.conversationId, messageToJson(message));
    }
    logger.info('updateMessageStatus took ${sw.elapsed}');
  }

  Future<Map<String, dynamic>> updateMessage(Parameters parameters, Peer peer) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.updateMessageStatus');
    final messageId = parameters['id'].asString;
    final dynamic metadata = parameters['metadata'].valueOr(null);
    final text = parameters['text'].asStringOr('');
    var message = await getMessageById.request(GetMessageByIdParameters(projectKey, messageId));
    if (message == null) {
      logger.warning('Message $messageId not found');
      logger.info('updateMessage took ${sw.elapsed}');
      throw RpcException(HttpStatus.notFound, 'Message not found', data: {'id': messageId});
    }
    final _user = _connectedUsers.firstWhere((element) => element.peer == peer, orElse: () => null);
    if (_user == null || !message.statusDetails.map((status) => status.id).contains(_user.data.id)) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    if (text != message.text && message.senderId != _user.data.id) {
      throw RpcException(HttpStatus.unauthorized, 'Not authorized');
    }
    message = await updateMessageRpc.request(message.copyWith(text: text, metadata: metadata));
    final conversation = await getConversationById.request(GetConversationByIdParameters(projectKey, message.conversationId));
    final others = _connectedUsers.where((user) => conversation.users.contains(_user.data)).where((user) => user.data.id != _user.data.id);
    final connectedOthers = [
      ...others,
      ..._connectedUsers.where((element) => element.data.id == _user.data.id).where((element) => element.peer != _user.peer),
    ];
    final messageJson = messageToJson(message);
    for (final other in connectedOthers) {
      logger.info('update message $message');
      other.updateMessage(message.conversationId, messageJson);
    }
    logger.info('updateMessage took ${sw.elapsed}');
    return messageJson;
  }
}
