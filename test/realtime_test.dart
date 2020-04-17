import 'dart:io';

import 'package:backend/src/api_v1/projects/realtime.dart';
import 'package:backend/src/models/conversation.dart';
import 'package:backend/src/models/message.dart';
import 'package:backend/src/models/project.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_rpc_2/error_code.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mocks/peer.dart';
import 'mocks/rpc/conversation/get_conversation_by_id.dart';
import 'mocks/rpc/conversation/save_conversation.dart';
import 'mocks/rpc/conversation/update_conversation_subject_and_avatar.dart';
import 'mocks/rpc/conversations/get_conversations_for_user.dart';
import 'mocks/rpc/messages/get_messages_for_conversation.dart';

void main() {
  test('add Peer', () async {
    final realtime = Realtime(Project('toto', null), null, null, null, null, null, null, null, null, null);
    realtime.addPeer(PeerMock());
    expect(realtime.connectedPeers.length, 1);
  });

  test('delete Peer', () async {
    final realtime = Realtime(Project('toto', null), null, null, null, null, null, null, null, null, null);
    final peer = PeerMock();
    realtime.addPeer(peer);
    realtime.removePeer(peer);
    expect(realtime.connectedPeers.length, 0);
  });

  test('register User', () async {
    final realtime = Realtime(Project('toto', null), null, null, null, null, null, null, null, null, null);
    final peer = PeerMock();
    realtime.addPeer(peer);

    realtime.registerUser(Parameters('registerUser', {'id': '1234'}), peer);
    expect(realtime.connectedUsers.length, 1);
  });

  group('get conversations', () {
    test('for users with no conversations', () async {
      final getUserConversationsMock = GetConversationsForUserMock();
      when(getUserConversationsMock.request(any)).thenAnswer((_) async => <Conversation>[]);
      final realtime = Realtime(Project('toto', null), null, null, null, null, getUserConversationsMock, null, null, null, null);
      final peer = PeerMock();
      realtime.addPeer(peer);
      realtime.registerUser(Parameters('registerUser', {'id': '1234'}), peer);
      final conversations = await realtime.getConversations(peer);
      expect(conversations, isEmpty);
    });

    test('for users with conversations', () async {
      final getUserConversationsMock = GetConversationsForUserMock();
      when(getUserConversationsMock.request(any)).thenAnswer((_) async => <Conversation>[
            Conversation('123', null, null, {'1'}, {'1', '2'})
          ]);
      final realtime = Realtime(Project('toto', null), null, null, null, null, getUserConversationsMock, null, null, null, null);
      final peer = PeerMock();
      realtime.addPeer(peer);
      realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
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
      final getConversationById = GetConversationByIdMock();
      final updateConversationSubjectAndAvatar = UpdateConversationSubjectAndAvatarParametersMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('1', null, null, {'1'}, {'1', '2'}));
      final realtime = Realtime(Project('toto', null), updateConversationSubjectAndAvatar, getConversationById, null, null, null, null, null, null, null);
      final peer = PeerMock();
      realtime.addPeer(peer);
      realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
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
      final getConversationById = GetConversationByIdMock();
      final updateConversationSubjectAndAvatar = UpdateConversationSubjectAndAvatarParametersMock();
      when(getConversationById.request(any)).thenThrow(RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': '1'}));
      final realtime = Realtime(Project('toto', null), updateConversationSubjectAndAvatar, getConversationById, null, null, null, null, null, null, null);
      final peer = PeerMock();
      realtime.addPeer(peer);
      realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
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
      final getConversationById = GetConversationByIdMock();
      final updateConversationSubjectAndAvatar = UpdateConversationSubjectAndAvatarParametersMock();
      when(getConversationById.request(any)).thenThrow(RpcException(HttpStatus.notFound, 'Conversation not found', data: <String, dynamic>{'id': '1'}));
      final realtime = Realtime(Project('toto', null), updateConversationSubjectAndAvatar, getConversationById, null, null, null, null, null, null, null);
      final peer = PeerMock();
      realtime.addPeer(peer);
      realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
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
      final realtime = Realtime(Project('toto', null), null, null, null, null, null, null, null, null, null);
      final peer = PeerMock();
      realtime.addPeer(peer);
      realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
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
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('1', null, null, {'1'}, {'1', '2'}));
      final realtime = Realtime(Project('toto', null), null, getConversationById, null, null, null, null, null, null, null);
      final peer = PeerMock();
      realtime.addPeer(peer);
      realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
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

    test('get conversation with subject', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('1', 'Test subject', null, {'1'}, {'1', '2'}));
      final realtime = Realtime(Project('toto', null), null, getConversationById, null, null, null, null, null, null, null);
      final peer = PeerMock();
      realtime.addPeer(peer);
      realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
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
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('1', null, 'https://avatarturl.com', {'1'}, {'1', '2'}));
      final realtime = Realtime(Project('toto', null), null, getConversationById, null, null, null, null, null, null, null);
      final peer = PeerMock();
      realtime.addPeer(peer);
      realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
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
        final getConversationById = GetConversationByIdMock();
        when(getConversationById.request(any)).thenAnswer((_) async => null);
        final realtime = Realtime(Project('toto', null), null, getConversationById, null, null, null, null, null, null, null);
        final peer = PeerMock();
        realtime.addPeer(peer);
        realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
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
        final sveConversation = SaveConversationMock();
        when(getConversationById.request(any)).thenAnswer((_) async => null);
        final realtime = Realtime(Project('toto', null), null, getConversationById, sveConversation, null, null, null, null, null, null);
        final peer = PeerMock();
        final other = PeerMock();
        realtime.addPeer(peer);
        realtime.addPeer(other);
        realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
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
        final realtime = Realtime(Project('toto', null), null, getConversationById, sveConversation, null, null, null, null, null, null);
        final peer = PeerMock();
        final other = PeerMock();
        when(other.sendRequest('onConversationCreated', any)).thenAnswer((_) => null);
        realtime.addPeer(peer);
        realtime.addPeer(other);
        realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
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
        verify(other.sendRequest('onConversationCreated', <String, dynamic>{
          'id': '1',
          'admins': ['1'],
          'users': ['1', '2', '3'],
          'messages': <dynamic>[],
        })).called(1);
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
      final realtime = Realtime(Project('toto', null), null, getConversationById, null, null, null, null, null, null, getMessagesForConversation);
      try {
        await realtime.getMessages(Parameters('getMessages', {'from': 0, 'to': -1, 'conversationId': '12'}));
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.notFound);
        expect(e.message, 'Conversation not found');
        expect(e.data, {'id': '12'});
      }
    });

    test('bad value of from and to', () async {
      final realtime = Realtime(Project('toto', null), null, null, null, null, null, null, null, null, null);
      try {
        await realtime.getMessages(Parameters('getMessages', {'from': 10, 'to': 1, 'conversationId': '12'}));
      } on RpcException catch (e) {
        expect(e.code, INVALID_PARAMS);
        expect(e.message, 'from can\'t be inferior at to');
      }
    });

    test('get all message', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}));
      final getMessagesForConversation = GetMessagesForConversationMock();
      when(getMessagesForConversation.request(any)).thenAnswer((_) async => [
            Message('toto', '2', '12', '1', 'How are you', DateTime.now(),
                [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
            Message('toto', '1', '12', '1', 'Hello world', DateTime.now(),
                [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
          ]);
      final realtime = Realtime(Project('toto', null), null, getConversationById, null, null, null, null, null, null, getMessagesForConversation);
      final response = await realtime.getMessages(Parameters('getMessages', {'from': 0, 'to': -1, 'conversationId': '12'}));
      expect(response.length == 2, isTrue);
    });

    test('get last message', () async {
      final getConversationById = GetConversationByIdMock();
      when(getConversationById.request(any)).thenAnswer((_) async => Conversation('12', null, null, {'1'}, {'1', '2'}));
      final getMessagesForConversation = GetMessagesForConversationMock();
      when(getMessagesForConversation.request(any)).thenAnswer((_) async => [
            Message('toto', '2', '12', '1', 'How are you', DateTime.now(),
                [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
            Message('toto', '1', '12', '1', 'Hello world', DateTime.now(),
                [MessageStateByUser('1', MessageState.seen), MessageStateByUser('2', MessageState.sent)]),
          ]);
      final realtime = Realtime(Project('toto', null), null, getConversationById, null, null, null, null, null, null, getMessagesForConversation);
      final response = await realtime.getMessages(Parameters('getMessages', {'from': 0, 'to': 1, 'conversationId': '12'}));
      expect(response.length == 1, isTrue);
      expect(response.first['text'], 'How are you');
    });
  });
}
