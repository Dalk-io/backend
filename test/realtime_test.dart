import 'dart:convert';
import 'dart:io';

import 'package:backend/src/api_v1/projects/realtime.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_rpc_2/error_code.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/mocks/peer.dart';
import 'src/realtime.dart';

void main() {
  Realtime realtime;

  setUp(() {
    realtime = initRealtime('testProjectKey');
  });

  test('add Peer', () async {
    final realtime = initRealtime('testProjectKey');
    realtime.addPeer(PeerMock());
    expect(realtime.connectedPeers.length, 1);
  });

  test('remove Peer', () async {
    final peer = PeerMock();
    realtime.addPeer(peer);
    await realtime.registerUser(Parameters('registerUser', <String, String>{'id': '1'}), peer);
    await realtime.removePeer(peer);
    expect(realtime.connectedUsers.length, 0);
    expect(realtime.connectedPeers.length, 0);
  });

  group('register user', () {
    test('isSecure false', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      expect(realtime.connectedUsers.length, 1);
    });

    test('secure', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      final signature = sha512.convert(utf8.encode('1234secret')).toString();
      await realtime.registerUser(Parameters('registerUser', {'id': '1', 'signature': signature}), peer);
      expect(realtime.connectedUsers.length, 1);
    });
  });

  group('get conversations', () {
    test('for users with no conversations', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '10'}), peer);
      final conversations = await realtime.getConversations(peer);
      expect(conversations, isEmpty);
    });

    test('for users with conversations', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final conversations = await realtime.getConversations(peer);
      expect(conversations, isNotEmpty);
      expect(conversations.length, 1);
      expect(conversations.first['id'], '1');
      expect(conversations.first['subject'], isNull);
      expect(conversations.first['avatar'], isNull);
      expect(conversations.first['admins'].length, 1);
      expect(conversations.first['users'].length, 2);
      expect(conversations.first['messages'], isEmpty);
    });
  });

  group('set conversation options', () {
    test('with existing conversation', () async {
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
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      try {
        await realtime.getOrCreateConversation(
          Parameters(
            'getOrCreateConversation',
            <String, dynamic>{
              'id': '404',
              'users': [
                {'id': '1'},
                {'id': '2'},
                {'id': '3'},
                {'id': '4'},
                {'id': '5'},
                {'id': '6'},
                {'id': '7'},
                {'id': '8'},
                {'id': '9'},
                {'id': '10'},
              ],
            },
          ),
          peer,
        );
        expect(true, isFalse);
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.unauthorized);
        expect(e.message, 'Group conversation limit');
        expect(e.data, {'groupLimitation': 5, 'groupSize': 9});
      }
    });

    test('get conversation with subject', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final conversation = await realtime.getOrCreateConversation(
        Parameters(
          'getOrCreateConversation',
          <String, dynamic>{
            'id': '2',
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
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final conversation = await realtime.getOrCreateConversation(
        Parameters(
          'getOrCreateConversation',
          <String, dynamic>{
            'id': '3',
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
              'id': '100',
              'users': [
                {'id': '1'},
                {'id': '2'}
              ],
            },
          ),
          peer,
        );
        expect(conversation, isMap);
        expect(conversation.containsKey('id'), isTrue);
        expect(conversation['id'], '100');
        expect(conversation.containsKey('users'), isTrue);
        expect(
            DeepCollectionEquality().equals(conversation['users'], [
              {'id': '1'},
              {'id': '2'}
            ]),
            isTrue);
        final otherUser = realtime.connectedUsers.firstWhere((user) => user.data.id == '2');
        final onConversationCreatedCalled = verifyNever(otherUser.onConversationCreated(<String, dynamic>{
          'id': '1',
          'admins': ['1'],
          'users': ['1', '2'],
        }));
        expect(onConversationCreatedCalled.callCount == 0, isTrue);
      });

      test('group', () async {
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
              'id': '5',
              'users': [
                {'id': '1'},
                {'id': '2'},
                {'id': '3'}
              ],
            },
          ),
          peer,
        );
        expect(conversation, isMap);
        expect(conversation.containsKey('id'), isTrue);
        expect(conversation['id'], '5');
        expect(conversation.containsKey('users'), isTrue);
        expect(
            DeepCollectionEquality().equals(conversation['users'], [
              {'id': '1'},
              {'id': '2'},
              {'id': '3'}
            ]),
            isTrue);
        verify(other.sendRequest('onConversationCreated', any)).called(1);
      });
    });
  });

  group('get messages', () {
    test('bad conversation id', () async {
      try {
        final peer = PeerMock();
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        await realtime.getMessages(Parameters('getMessages', {'from': 0, 'to': -1, 'conversationId': '1000'}), peer);
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.notFound);
        expect(e.message, 'Conversation not found');
        expect(e.data, {'id': '1000'});
      }
    });

    test('bad value of from and to', () async {
      final peer = PeerMock();
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      try {
        await realtime.getMessages(Parameters('getMessages', {'from': 10, 'to': 1, 'conversationId': '12'}), peer);
      } on RpcException catch (e) {
        expect(e.code, INVALID_PARAMS);
        expect(e.message, 'from can\'t be inferior at to');
      }
    });

    test('get all message', () async {
      final peer = PeerMock();
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final response = await realtime.getMessages(Parameters('getMessages', {'from': 0, 'to': -1, 'conversationId': '6'}), peer);
      expect(response.length == 2, isTrue);
    });

    test('get last message', () async {
      final peer = PeerMock();
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final response = await realtime.getMessages(Parameters('getMessages', {'from': 0, 'to': 1, 'conversationId': '6'}), peer);
      expect(response.length == 1, isTrue);
      expect(response.first['text'], 'How are you?');
    });
  });

  group('get conversation details', () {
    test('bad conversation id', () async {
      final peer = PeerMock();
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      try {
        await realtime.getConversationDetail(Parameters('getConversationDetails', {'id': '12'}), peer);
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.notFound);
        expect(e.message, 'Conversation not found');
        expect(e.data, {'id': '12'});
      }
    });

    test('valid conversation', () async {
      final peer = PeerMock();
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final response = await realtime.getConversationDetail(Parameters('getConversationDetails', {'id': '7'}), peer);
      expect(response['id'], '7');
      expect(response['messages'].length, 1);
    });
  });

  group('send message', () {
    test('conversation not found', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      try {
        await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '404'}), peer);
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.notFound);
        expect(e.message, 'Conversation not found');
        expect(e.data, {'id': '404'});
      }
    });

    group('first message in 1:1 conversation', () {
      test('when other is connected', () async {
        final peer = PeerMock();
        final other = PeerMock();
        realtime..addPeer(peer)..addPeer(other);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '13', 'text': 'Hello world'}), peer);
        expect(response.isNotEmpty, isTrue);
        expect(
          DeepCollectionEquality().equals(response, {
            'id': '1',
            'senderId': '1',
            'text': 'Hello world',
            'timestamp': '2020-01-01T14:30:00.000Z',
            'statusDetails': [
              {'id': '2', 'status': 'sent'},
            ],
            'status': 'sent',
          }),
          isTrue,
        );
        verify(other.sendRequest('onConversationCreated', any)).called(1);
        verifyNever(other.sendRequest('receiveMessage13', any));
      });

      test('when other is not connected', () async {
        final peer = PeerMock();
        final other = PeerMock();
        realtime..addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '13', 'text': 'Hello world'}), peer);
        expect(response.isNotEmpty, isTrue);
        verifyNever(other.sendRequest('onConversationCreated', any));
        verifyNever(other.sendRequest('receiveMessage12', any));
        expect(
          DeepCollectionEquality().equals(response, {
            'id': '1',
            'senderId': '1',
            'text': 'Hello world',
            'timestamp': '2020-01-01T14:30:00.000Z',
            'status': 'sent',
            'statusDetails': [
              {'id': '2', 'status': 'sent'},
            ]
          }),
          isTrue,
        );
      });
    });

    test('1:1 multiple message in conversation', () async {
      final peer = PeerMock();
      final other = PeerMock();
      realtime..addPeer(peer)..addPeer(other);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
      final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '14', 'text': 'Hello world'}), peer);
      expect(response.isNotEmpty, isTrue);
      verifyNever(other.sendRequest('onConversationCreated', any));
      verify(other.sendRequest('receiveMessage14', any)).called(1);
      expect(
        DeepCollectionEquality().equals(response, {
          'id': '1',
          'senderId': '1',
          'text': 'Hello world',
          'timestamp': '2020-01-01T14:30:00.000Z',
          'status': 'sent',
          'statusDetails': [
            {'id': '2', 'status': 'sent'},
          ]
        }),
        isTrue,
      );
    });

    test('first message in group conversation', () async {
      final peer = PeerMock();
      final other1 = PeerMock();
      final other2 = PeerMock();
      realtime..addPeer(peer)..addPeer(other1)..addPeer(other2);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other1);
      await realtime.registerUser(Parameters('registerUser', {'id': '3'}), other2);
      final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '15', 'text': 'Hello world'}), peer);
      expect(response.isNotEmpty, isTrue);
      verifyNever(other1.sendRequest('onConversationCreated', any));
      verify(other1.sendRequest('receiveMessage15', any)).called(1);
      verify(other2.sendRequest('receiveMessage15', any)).called(1);
      verifyNever(realtime.httpClient.post(any, body: anyNamed('body')));
      expect(
        DeepCollectionEquality().equals(response, {
          'id': '1',
          'senderId': '1',
          'text': 'Hello world',
          'timestamp': '2020-01-01T14:30:00.000Z',
          'status': 'sent',
          'statusDetails': [
            {'id': '2', 'status': 'sent'},
            {'id': '3', 'status': 'sent'}
          ]
        }),
        isTrue,
      );
    });

    test('with webHook', () async {
      final realtimeWithWebHook = initRealtime('key-with-web-hook', withWebHook: true);
      final peer = PeerMock();
      final other = PeerMock();
      realtimeWithWebHook..addPeer(peer)..addPeer(other);
      await realtimeWithWebHook.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      await realtimeWithWebHook.registerUser(Parameters('registerUser', {'id': '2'}), other);
      final response = await realtimeWithWebHook.sendMessage(Parameters('sendMessage', {'conversationId': '13', 'text': 'Hello world'}), peer);
      expect(response.isNotEmpty, isTrue);
      verify(other.sendRequest('onConversationCreated', any)).called(1);
      verifyNever(other.sendRequest('receiveMessage13', any));
      verify(realtimeWithWebHook.httpClient.post(any, body: anyNamed('body'))).called(1);
      expect(
        DeepCollectionEquality().equals(response, {
          'id': '1',
          'senderId': '1',
          'text': 'Hello world',
          'timestamp': '2020-01-01T14:30:00.000Z',
          'status': 'sent',
          'statusDetails': [
            {'id': '2', 'status': 'sent'},
          ]
        }),
        isTrue,
      );
    });
  });

  group('update message status', () {
    test('message not found', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      try {
        await realtime.updateMessageStatus(Parameters('updateMessageStatus', {'id': '1', 'status': messageStatusToString(MessageStatus.sent)}), peer);
      } on RpcException catch (e) {
        expect(e.code, HttpStatus.notFound);
      }
    });

    test('seen to sent', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      await realtime.updateMessageStatus(Parameters('updateMessageStatus', {'id': '1', 'status': messageStatusToString(MessageStatus.sent)}), peer);
      verifyNever(peer.sendRequest(any));
    });

    test('sent to seen', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final other = PeerMock();
      realtime.addPeer(other);
      await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
      await realtime.updateMessageStatus(
          Parameters('updateMessageStatus', <String, dynamic>{'id': '2', 'status': messageStatusToString(MessageStatus.seen)}), other);
      verify(peer.sendRequest('updateMessageStatus17', {
        'id': '2',
        'senderId': '1',
        'text': 'Hello world',
        'timestamp': '2020-01-01T14:30:00.000Z',
        'status': 'seen',
        'statusDetails': [
          {'id': '2', 'status': 'seen'}
        ]
      })).called(1);
    });

    test('sent to seen send only to user in conversation', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final other = PeerMock();
      realtime.addPeer(other);
      await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
      final other1 = PeerMock();
      realtime.addPeer(other1);
      await realtime.registerUser(Parameters('registerUser', {'id': '3'}), other1);
      await realtime.updateMessageStatus(
          Parameters('updateMessageStatus', <String, dynamic>{'id': '2', 'status': messageStatusToString(MessageStatus.seen)}), other);
      verifyNever(other1.sendRequest('updateMessageStatus17', any));
    });

    test('seen to seen', () async {
      final peer = PeerMock();
      realtime.addPeer(peer);
      await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
      final other = PeerMock();
      realtime.addPeer(other);
      await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
      await realtime.updateMessageStatus(Parameters('updateMessageStatus', {'id': '3', 'status': messageStatusToString(MessageStatus.seen)}), other);
      verifyNever(peer.sendRequest('updateMessageStatus17', any));
    });
  });
}
