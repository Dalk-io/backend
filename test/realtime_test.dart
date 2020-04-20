import 'dart:convert';
import 'dart:io';

import 'package:backend/src/api_v1/projects/realtime.dart';
import 'package:backend/src/models/conversation.dart';
import 'package:backend/src/models/message.dart';
import 'package:backend/src/models/project.dart';
import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_rpc_2/error_code.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks/io_client.dart';
import 'mocks/peer.dart';
import 'mocks/rpc/conversation/get_conversation_by_id.dart';
import 'mocks/rpc/conversation/get_number_of_message_for_conversation.dart';
import 'mocks/rpc/conversation/save_conversation.dart';
import 'mocks/rpc/conversation/update_conversation_last_update.dart';
import 'mocks/rpc/conversation/update_conversation_subject_and_avatar.dart';
import 'mocks/rpc/conversations/get_conversations_for_user.dart';
import 'mocks/rpc/message/get_message_by_id.dart';
import 'mocks/rpc/message/save_message.dart';
import 'mocks/rpc/message/update_message_state.dart';
import 'mocks/rpc/messages/get_messages_for_conversation.dart';
import 'mocks/rpc/project/get_project_by_key.dart';

void main() {
  test('add Peer', () async {
    final realtime = Realtime(ProjectInformations('toto', null), null, null, null, null, null, null, null, null, null, null, null);
    realtime.addPeer(PeerMock());
    expect(realtime.connectedPeers.length, 1);
  });

  test('delete Peer', () async {
    final realtime = Realtime(ProjectInformations('toto', null), null, null, null, null, null, null, null, null, null, null, null);
    final peer = PeerMock();
    realtime.addPeer(peer);
    realtime.removePeer(peer);
    expect(realtime.connectedPeers.length, 0);
  });

  group('register user', () {
    test('unsecure', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'secret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final realtime = Realtime(ProjectInformations('toto', null), null, null, null, null, null, null, null, null, null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1234'}), peer);
      expect(realtime.connectedUsers.length, 1);
    });

    test('secure', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2, secure: true),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );

      final projectInformations = ProjectInformations('toto', 'mysecret', secure: true);
      final realtime = Realtime(projectInformations, null, null, null, null, null, null, null, null, null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      final signature = sha512.convert(utf8.encode('1234${projectInformations.secret}')).toString();
      await realtime.registerUser(Parameters('registerUser', {'id': '1234', 'signature': signature}), peer);
      expect(realtime.connectedUsers.length, 1);
    });
  });

  group('get conversations', () {
    test('for users with no conversations', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'secret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getUserConversationsMock = GetConversationsForUserMock();
      when(getUserConversationsMock.request(any)).thenAnswer((_) async => <Conversation>[]);
      final realtime =
          Realtime(ProjectInformations('toto', null), null, null, null, null, null, getUserConversationsMock, null, null, null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1234'}), peer);
      final conversations = await realtime.getConversations(peer);
      expect(conversations, isEmpty);
    });

    test('for users with conversations', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getUserConversationsMock = GetConversationsForUserMock();
      when(getUserConversationsMock.request(any)).thenAnswer((_) async => <Conversation>[
            Conversation('123', null, null, {'1'}, {'1', '2'}, false)
          ]);
      final realtime =
          Realtime(ProjectInformations('toto', null), null, null, null, null, null, getUserConversationsMock, null, null, null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final conversations = await realtime.getConversations(peer);
      expect(conversations, isNotEmpty);
      expect(conversations.length, 1);
      expect(conversations.first['id'], '123');
      expect(conversations.first['subject'], isNull);
      expect(conversations.first['avatar'], isNull);
      expect(conversations.first['admins'].length, 1);
      expect(conversations.first['users'].length, 2);
      expect(conversations.first['messages'], isEmpty);
    });
  });

  group('set conversation options', () {
    test('with existing conversation', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getConversationById = GetConversationByIdMock();
      final updateConversationSubjectAndAvatar = UpdateConversationSubjectAndAvatarParametersMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('1', null, null, {'1'}, {'1', '2'}, false));
      final realtime = Realtime(ProjectInformations('toto', null), updateConversationSubjectAndAvatar, getConversationById, null, null, null, null, null, null,
          null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      await realtime.setConversationOptions(
        Parameters(
          'setConversationOptions',
          <String, dynamic>{
            'conversationId': '1',
            'subject': 'Test',
          },
        ),
        peer,
      );
      expect(true, isTrue);
    });

    test('with non existing conversation', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getConversationById = GetConversationByIdMock();
      final updateConversationSubjectAndAvatar = UpdateConversationSubjectAndAvatarParametersMock();
      when(getConversationById.request(any)).thenThrow(RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': '1'}));
      final realtime = Realtime(ProjectInformations('toto', null), updateConversationSubjectAndAvatar, getConversationById, null, null, null, null, null, null,
          null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      try {
        await realtime.setConversationOptions(
          Parameters(
            'setConversationOptions',
            <String, dynamic>{
              'conversationId': '1',
              'subject': 'Test',
            },
          ),
          peer,
        );
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.notFound);
        expect(e.message, 'Conversation not found');
        expect((e.data as Map<String, dynamic>).containsKey('id'), isTrue);
        expect((e.data as Map<String, dynamic>)['id'], '1');
      }
    });

    test('without conversationId in parameters', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getConversationById = GetConversationByIdMock();
      final updateConversationSubjectAndAvatar = UpdateConversationSubjectAndAvatarParametersMock();
      when(getConversationById.request(any)).thenThrow(RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': '1'}));
      final realtime = Realtime(ProjectInformations('toto', null), updateConversationSubjectAndAvatar, getConversationById, null, null, null, null, null, null,
          null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      try {
        await realtime.setConversationOptions(
          Parameters(
            'setConversationOptions',
            <String, dynamic>{
              'subject': 'Test',
            },
          ),
          peer,
        );
      } on RpcException catch (e) {
        expect(e.code, INVALID_PARAMS);
      }
    });
  });

  group('get or create conversation', () {
    test('without conversationId in parameters', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final realtime = Realtime(ProjectInformations('toto', null), null, null, null, null, null, null, null, null, null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      try {
        await realtime.getOrCreateConversation(
          Parameters(
            'getOrCreateConversation',
            <String, dynamic>{},
          ),
          peer,
        );
      } on RpcException catch (e) {
        expect(e.code, INVALID_PARAMS);
      }
    });

    test('get conversation', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('1', null, null, {'1'}, {'1', '2'}, false));
      final realtime = Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, null, null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final conversation = await realtime.getOrCreateConversation(
        Parameters(
          'getOrCreateConversation',
          <String, dynamic>{
            'id': '1',
          },
        ),
        peer,
      );
      expect(conversation, isMap);
      expect(conversation.containsKey('id'), isTrue);
      expect(conversation.containsKey('admins'), isTrue);
      expect(conversation.containsKey('users'), isTrue);
      expect(conversation.containsKey('avatar'), isFalse);
      expect(conversation.containsKey('subject'), isFalse);
    });

    test('group limit', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => null);
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'secret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final saveConversation = SaveConversationMock();
      final realtime =
          Realtime(ProjectInformations('toto', null), null, getConversationById, saveConversation, null, null, null, null, null, null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      try {
        await realtime.getOrCreateConversation(
          Parameters(
            'getOrCreateConversation',
            <String, dynamic>{
              'id': '1',
              'users': ['1', '2', '3', '4', '5', '6'],
            },
          ),
          peer,
        );
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.unauthorized);
        expect(e.message, 'Group conversation limit');
        expect(e.data, {'groupLimitation': 2, 'groupSize': 5});
      }
    });

    test('get conversation with subject', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('1', 'Test subject', null, {'1'}, {'1', '2'}, false));
      final realtime = Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, null, null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final conversation = await realtime.getOrCreateConversation(
        Parameters(
          'getOrCreateConversation',
          <String, dynamic>{
            'id': '1',
          },
        ),
        peer,
      );
      expect(conversation, isMap);
      expect(conversation.containsKey('id'), isTrue);
      expect(conversation.containsKey('admins'), isTrue);
      expect(conversation.containsKey('users'), isTrue);
      expect(conversation.containsKey('avatar'), isFalse);
      expect(conversation.containsKey('subject'), isTrue);
    });

    test('get conversation with avatar', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('1', null, 'https://avatarturl.com', {'1'}, {'1', '2'}, false));
      final realtime = Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, null, null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final conversation = await realtime.getOrCreateConversation(
        Parameters(
          'getOrCreateConversation',
          <String, dynamic>{
            'id': '1',
          },
        ),
        peer,
      );
      expect(conversation, isMap);
      expect(conversation.containsKey('id'), isTrue);
      expect(conversation.containsKey('admins'), isTrue);
      expect(conversation.containsKey('users'), isTrue);
      expect(conversation.containsKey('avatar'), isTrue);
      expect(conversation.containsKey('subject'), isFalse);
    });

    group('create conversation', () {
      test('without to parameters', () async {
        final getProjectByKey = GetProjectByKeyMock();
        when(getProjectByKey.request(any)).thenAnswer(
          (_) async => Project(
            production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
            development: ProjectInformations('toto_dev', 'secret'),
          ),
        );
        final getConversationById = GetConversationByIdMock();
        when(getConversationById.request(any)).thenAnswer((_) async => null);
        final realtime =
            Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, null, null, null, getProjectByKey);
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        try {
          await realtime.getOrCreateConversation(
            Parameters(
              'getOrCreateConversation',
              <String, dynamic>{},
            ),
            peer,
          );
        } on RpcException catch (e) {
          expect(e.code, INVALID_PARAMS);
        }
      });

      test('one to one', () async {
        final getConversationById = GetConversationByIdMock();
        final saveConversation = SaveConversationMock();
        when(getConversationById.request(any)).thenAnswer((_) async => null);
        final getProjectByKey = GetProjectByKeyMock();
        when(getProjectByKey.request(any)).thenAnswer(
          (_) async => Project(
            production: ProjectInformations('toto', 'secret'),
            development: ProjectInformations('toto_dev', 'secret'),
          ),
        );
        final realtime =
            Realtime(ProjectInformations('toto', null), null, getConversationById, saveConversation, null, null, null, null, null, null, null, getProjectByKey);
        final peer = PeerMock();
        final other = PeerMock();
        realtime.addPeer(peer);
        realtime.addPeer(other);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        final conversation = await realtime.getOrCreateConversation(
          Parameters(
            'getOrCreateConversation',
            <String, dynamic>{
              'id': '1',
              'users': ['1', '2'],
            },
          ),
          peer,
        );
        expect(conversation, isMap);
        expect(conversation.containsKey('id'), isTrue);
        expect(conversation['id'], '1');
        expect(conversation.containsKey('users'), isTrue);
        expect(DeepCollectionEquality().equals(conversation['users'], ['1', '2']), isTrue);
        final otherUser = realtime.connectedUsers.firstWhere((user) => user.id == '2');
        final onConversationCreatedCalled = verifyNever(otherUser.onConversationCreated(<String, dynamic>{
          'id': '1',
          'admins': ['1'],
          'users': ['1', '2'],
        }));
        expect(onConversationCreatedCalled.callCount == 0, isTrue);
      });

      test('group', () async {
        final getConversationById = GetConversationByIdMock();
        final sveConversation = SaveConversationMock();
        when(getConversationById.request(any)).thenAnswer((_) async => null);
        final getProjectByKey = GetProjectByKeyMock();
        when(getProjectByKey.request(any)).thenAnswer(
          (_) async => Project(
            production: ProjectInformations('toto', 'secret'),
            development: ProjectInformations('toto_dev', 'secret'),
          ),
        );
        final realtime =
            Realtime(ProjectInformations('toto', null), null, getConversationById, sveConversation, null, null, null, null, null, null, null, getProjectByKey);
        final peer = PeerMock();
        final other = PeerMock();
        when(other.sendRequest('onConversationCreated', any)).thenAnswer((_) => null);
        realtime.addPeer(peer);
        realtime.addPeer(other);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        final conversation = await realtime.getOrCreateConversation(
          Parameters(
            'getOrCreateConversation',
            <String, dynamic>{
              'id': '1',
              'users': ['1', '2', '3'],
            },
          ),
          peer,
        );
        expect(conversation, isMap);
        expect(conversation.containsKey('id'), isTrue);
        expect(conversation['id'], '1');
        expect(conversation.containsKey('users'), isTrue);
        expect(DeepCollectionEquality().equals(conversation['users'], ['1', '2', '3']), isTrue);
        verify(other.sendRequest('onConversationCreated', any)).called(1);
      });
    });
  });

  group('get messages', () {
    test('bad conversation id', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => null);
      final getMessagesForConversation = GetMessagesForConversationMock();
      when(getMessagesForConversation.request(any)).thenAnswer((_) async => [
            Message('toto', '1', '12', '1', 'Hello world', DateTime.now(),
                [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
            Message('toto', '2', '12', '1', 'How are you', DateTime.now(),
                [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
          ]);
      final realtime =
          Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, null, null, getMessagesForConversation, null);
      try {
        await realtime.getMessages(Parameters('getMessages', {'from': 0, 'to': -1, 'conversationId': '12'}));
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.notFound);
        expect(e.message, 'Conversation not found');
        expect(e.data, {'id': '12'});
      }
    });

    test('bad value of from and to', () async {
      final realtime = Realtime(ProjectInformations('toto', null), null, null, null, null, null, null, null, null, null, null, null);
      try {
        await realtime.getMessages(Parameters('getMessages', {'from': 10, 'to': 1, 'conversationId': '12'}));
      } on RpcException catch (e) {
        expect(e.code, INVALID_PARAMS);
        expect(e.message, 'from can\'t be inferior at to');
      }
    });

    test('get all message', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}, false));
      final getMessagesForConversation = GetMessagesForConversationMock();
      when(getMessagesForConversation.request(any)).thenAnswer((_) async => [
            Message('toto', '2', '12', '1', 'How are you', DateTime.now(),
                [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
            Message('toto', '1', '12', '1', 'Hello world', DateTime.now(),
                [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
          ]);
      final realtime =
          Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, null, null, getMessagesForConversation, null);
      final response = await realtime.getMessages(Parameters('getMessages', {'from': 0, 'to': -1, 'conversationId': '12'}));
      expect(response.length == 2, isTrue);
    });

    test('get last message', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}, false));
      final getMessagesForConversation = GetMessagesForConversationMock();
      when(getMessagesForConversation.request(any)).thenAnswer((_) async => [
            Message('toto', '2', '12', '1', 'How are you', DateTime.now(),
                [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
            Message('toto', '1', '12', '1', 'Hello world', DateTime.now(),
                [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
          ]);
      final realtime =
          Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, null, null, getMessagesForConversation, null);
      final response = await realtime.getMessages(Parameters('getMessages', {'from': 0, 'to': 1, 'conversationId': '12'}));
      expect(response.length == 1, isTrue);
      expect(response.first['text'], 'How are you');
    });
  });

  group('get conversation details', () {
    test('bad conversation id', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => null);
      final realtime = Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, null, null, null, null);
      try {
        await realtime.getConversationDetail(Parameters('getConversationDetails', {'id': '12'}));
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.notFound);
        expect(e.message, 'Conversation not found');
        expect(e.data, {'id': '12'});
      }
    });

    test('valid conversation', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}, false)
        ..messages.addAll([
          Message('toto', '1', '12', '1', 'Hello world!', DateTime.now(), [MessageStateByUser('2', MessageState.sent)]),
        ]));
      final realtime = Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, null, null, null, null);
      final response = await realtime.getConversationDetail(Parameters('getConversationDetails', {'id': '12'}));
      expect(response['id'], '12');
      expect(response['messages'].length, 1);
    });
  });

  group('send message', () {
    test('conversation not found', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => null);
      final realtime = Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, null, null, null, null);
      final peer = PeerMock();
      realtime.addPeer(peer);
      try {
        await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '12'}), peer);
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.notFound);
        expect(e.message, 'Conversation not found');
        expect(e.data, {'id': '12'});
      }
    });

    group('first message in 1:1 conversation', () {
      test('when other is connected', () async {
        final getConversationById = GetConversationByIdMock();
        when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}, false));
        final saveMessage = SaveMessageMock();
        when(saveMessage.request(any)).thenAnswer((_) async => 1);
        final getNumberOfMessageForConversation = GetNumberOfMessageForConversationMock();
        when(getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
        final getProjectByKey = GetProjectByKeyMock();
        when(getProjectByKey.request(any)).thenAnswer(
          (_) async => Project(
            production: ProjectInformations('toto', 'secret'),
            development: ProjectInformations('toto_dev', 'secret'),
          ),
        );
        final updateConversationLastUpdate = UpdateConversationLastUpdateMock();
        final peer = PeerMock();
        final other = PeerMock();
        final realtime = Realtime(
          ProjectInformations('toto', null),
          null,
          getConversationById,
          null,
          updateConversationLastUpdate,
          getNumberOfMessageForConversation,
          null,
          saveMessage,
          null,
          null,
          null,
          getProjectByKey,
          dateTimeFactory: () => DateTime.utc(2020, 01, 01, 14, 30),
        );
        realtime..addPeer(peer)..addPeer(other);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '12', 'text': 'Hello world'}), peer);
        expect(response.isNotEmpty, isTrue);
        verify(other.sendRequest('onConversationCreated', any)).called(1);
        verifyNever(other.sendRequest('receiveMessage12', any));
        expect(
          DeepCollectionEquality().equals(response, {
            'id': '1',
            'senderId': '1',
            'text': 'Hello world',
            'timestamp': '2020-01-01T14:30:00.000Z',
            'state': 0,
            'stateDetails': [
              {'userId': '2', 'state': 0},
            ]
          }),
          isTrue,
        );
      });

      test('when other is not connected', () async {
        final getConversationById = GetConversationByIdMock();
        when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}, false));
        final saveMessage = SaveMessageMock();
        when(saveMessage.request(any)).thenAnswer((_) async => 1);
        final updateConversationLastUpdate = UpdateConversationLastUpdateMock();
        final getNumberOfMessageForConversation = GetNumberOfMessageForConversationMock();
        when(getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
        final getProjectByKey = GetProjectByKeyMock();
        when(getProjectByKey.request(any)).thenAnswer(
          (_) async => Project(
            production: ProjectInformations('toto', 'secret'),
            development: ProjectInformations('toto_dev', 'secret'),
          ),
        );
        final peer = PeerMock();
        final other = PeerMock();
        final realtime = Realtime(
          ProjectInformations('toto', null),
          null,
          getConversationById,
          null,
          updateConversationLastUpdate,
          getNumberOfMessageForConversation,
          null,
          saveMessage,
          null,
          null,
          null,
          getProjectByKey,
          dateTimeFactory: () => DateTime.utc(2020, 01, 01, 14, 30),
        );
        realtime..addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '12', 'text': 'Hello world'}), peer);
        expect(response.isNotEmpty, isTrue);
        verifyNever(other.sendRequest('onConversationCreated', any));
        verifyNever(other.sendRequest('receiveMessage12', any));
        expect(
          DeepCollectionEquality().equals(response, {
            'id': '1',
            'senderId': '1',
            'text': 'Hello world',
            'timestamp': '2020-01-01T14:30:00.000Z',
            'state': 0,
            'stateDetails': [
              {'userId': '2', 'state': 0},
            ]
          }),
          isTrue,
        );
      });
    });

    test('1:1 multiple message in conversation', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}, false));
      final saveMessage = SaveMessageMock();
      when(saveMessage.request(any)).thenAnswer((_) async => 1);
      final getNumberOfMessageForConversation = GetNumberOfMessageForConversationMock();
      when(getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 13);
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'secret', webhook: 'http://test.com'),
          development: ProjectInformations('toto_dev', 'secret', webhook: 'http://test.com'),
        ),
      );
      final updateConversationLastUpdate = UpdateConversationLastUpdateMock();
      final peer = PeerMock();
      final other = PeerMock();
      final realtime = Realtime(
        ProjectInformations('toto', null),
        null,
        getConversationById,
        null,
        updateConversationLastUpdate,
        getNumberOfMessageForConversation,
        null,
        saveMessage,
        null,
        null,
        null,
        getProjectByKey,
        dateTimeFactory: () => DateTime.utc(2020, 01, 01, 14, 30),
      );
      realtime..addPeer(peer)..addPeer(other);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
      final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '12', 'text': 'Hello world'}), peer);
      expect(response.isNotEmpty, isTrue);
      verifyNever(other.sendRequest('onConversationCreated', any));
      verify(other.sendRequest('receiveMessage12', any)).called(1);
      expect(
        DeepCollectionEquality().equals(response, {
          'id': '1',
          'senderId': '1',
          'text': 'Hello world',
          'timestamp': '2020-01-01T14:30:00.000Z',
          'state': 0,
          'stateDetails': [
            {'userId': '2', 'state': 0},
          ]
        }),
        isTrue,
      );
    });

    test('first message in group conversation', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('123', null, null, {'1'}, {'1', '2', '3'}, true));
      final saveMessage = SaveMessageMock();
      when(saveMessage.request(any)).thenAnswer((_) async => 1);
      final updateConversationLastUpdate = UpdateConversationLastUpdateMock();
      final getNumberOfMessageForConversation = GetNumberOfMessageForConversationMock();
      when(getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'secret'),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final peer = PeerMock();
      final other1 = PeerMock();
      final other2 = PeerMock();
      final ioClient = IOClientMock();
      final realtime = Realtime(
        ProjectInformations('toto', null),
        null,
        getConversationById,
        null,
        updateConversationLastUpdate,
        getNumberOfMessageForConversation,
        null,
        saveMessage,
        null,
        null,
        null,
        getProjectByKey,
        dateTimeFactory: () => DateTime.utc(2020, 01, 01, 14, 30),
        httpClient: ioClient,
      );
      realtime..addPeer(peer)..addPeer(other1)..addPeer(other2);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other1);
      await realtime.registerUser(Parameters('registerUser', {'id': '3'}), other2);
      final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '12', 'text': 'Hello world'}), peer);
      expect(response.isNotEmpty, isTrue);
      verifyNever(other1.sendRequest('onConversationCreated', any));
      verify(other1.sendRequest('receiveMessage123', any)).called(1);
      verify(other2.sendRequest('receiveMessage123', any)).called(1);
      verifyNever(ioClient.post(any, body: anyNamed('body')));
      expect(
        DeepCollectionEquality().equals(response, {
          'id': '1',
          'senderId': '1',
          'text': 'Hello world',
          'timestamp': '2020-01-01T14:30:00.000Z',
          'state': 0,
          'stateDetails': [
            {'userId': '2', 'state': 0},
            {'userId': '3', 'state': 0}
          ]
        }),
        isTrue,
      );
    });

    test('with webhook', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}, false));
      final saveMessage = SaveMessageMock();
      when(saveMessage.request(any)).thenAnswer((_) async => 1);
      final updateConversationLastUpdate = UpdateConversationLastUpdateMock();
      final getNumberOfMessageForConversation = GetNumberOfMessageForConversationMock();
      when(getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'secret', webhook: 'http://test.com'),
          development: ProjectInformations('toto_dev', 'secret', webhook: 'http://test.com'),
        ),
      );
      final peer = PeerMock();
      final other = PeerMock();
      final ioClient = IOClientMock();
      final realtime = Realtime(
        ProjectInformations('toto', null),
        null,
        getConversationById,
        null,
        updateConversationLastUpdate,
        getNumberOfMessageForConversation,
        null,
        saveMessage,
        null,
        null,
        null,
        getProjectByKey,
        dateTimeFactory: () => DateTime.utc(2020, 01, 01, 14, 30),
        httpClient: ioClient,
      );
      realtime..addPeer(peer)..addPeer(other);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
      final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '12', 'text': 'Hello world'}), peer);
      expect(response.isNotEmpty, isTrue);
      verify(other.sendRequest('onConversationCreated', any)).called(1);
      verifyNever(other.sendRequest('receiveMessage12', any));
      verify(ioClient.post(any, body: anyNamed('body'))).called(1);
      expect(
        DeepCollectionEquality().equals(response, {
          'id': '1',
          'senderId': '1',
          'text': 'Hello world',
          'timestamp': '2020-01-01T14:30:00.000Z',
          'state': 0,
          'stateDetails': [
            {'userId': '2', 'state': 0},
          ]
        }),
        isTrue,
      );
    });
  });

  group('update message state', () {
    test('message not found', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getMessageById = GetMessageByIdMock();
      when(getMessageById.request(any)).thenAnswer((_) async => null);
      final peer = PeerMock();
      final realtime = Realtime(ProjectInformations('toto', null), null, null, null, null, null, null, null, getMessageById, null, null, getProjectByKey);
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      try {
        await realtime.updateMessageState(Parameters('updateMessageState', {'id': '1', 'state': 2}), peer);
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.notFound);
      }
    });

    test('seen to sent', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getMessageById = GetMessageByIdMock();
      when(getMessageById.request(any)).thenAnswer(
        (_) async => Message('toto', '1', '12', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30), [
          MessageStateByUser('1', MessageState.seen),
        ]),
      );
      final realtime = Realtime(ProjectInformations('toto', null), null, null, null, null, null, null, null, getMessageById, null, null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      await realtime.updateMessageState(Parameters('updateMessageState', {'id': '1', 'state': MessageState.sent.index}), peer);
      verifyNever(peer.sendRequest(any));
    });

    test('sent to seen', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getMessageById = GetMessageByIdMock();
      when(getMessageById.request(any)).thenAnswer(
        (_) async => Message('toto', '1', '12', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
            [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
      );
      final udpateMessageState = UpdateMessageStateMock();
      when(udpateMessageState.request(any)).thenAnswer(
        (_) async => Message('toto', '1', '12', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
            [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.seen)]),
      );
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}, false));
      final realtime = Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, getMessageById, udpateMessageState,
          null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final other = PeerMock();
      realtime.addPeer(other);
      await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
      await realtime.updateMessageState(Parameters('updateMessageState', {'id': '2', 'state': MessageState.seen.index}), other);
      verify(peer.sendRequest('updateMessageState12', {
        'id': '1',
        'senderId': '1',
        'text': 'Hello world',
        'timestamp': '2020-01-01T14:30:00.000Z',
        'state': 2,
        'stateDetails': [
          {'userId': '2', 'state': 2}
        ]
      })).called(1);
    });

    test('seen to seen', () async {
      final getProjectByKey = GetProjectByKeyMock();
      when(getProjectByKey.request(any)).thenAnswer(
        (_) async => Project(
          production: ProjectInformations('toto', 'mysecret', groupLimitation: 2),
          development: ProjectInformations('toto_dev', 'secret'),
        ),
      );
      final getMessageById = GetMessageByIdMock();
      when(getMessageById.request(any)).thenAnswer(
        (_) async => Message('toto', '1', '12', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
            [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.seen)]),
      );
      final udpateMessageState = UpdateMessageStateMock();
      when(udpateMessageState.request(any)).thenAnswer(
        (_) async => Message('toto', '1', '12', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
            [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.seen)]),
      );
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}, false));
      final realtime = Realtime(ProjectInformations('toto', null), null, getConversationById, null, null, null, null, null, getMessageById, udpateMessageState,
          null, getProjectByKey);
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final other = PeerMock();
      realtime.addPeer(other);
      await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
      await realtime.updateMessageState(Parameters('updateMessageState', {'id': '2', 'state': MessageState.seen.index}), other);
      verifyNever(peer.sendRequest('updateMessageState12', any));
    });
  });
}
