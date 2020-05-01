import 'dart:convert';
import 'dart:io';

import 'package:backend/src/api_v1/projects/realtime.dart';
import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/data/user/user.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_rpc_2/error_code.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/mocks/peer.dart';
import 'src/realtimes/realtime.dart';

void main() {
  final starterProject = ProjectsData(ProjectEnvironmentData('dev-key', '12345'));
  // final productionSecureStarterWithProject = ProjectsData(
  //   ProjectEnvironmentData('dev-starter-key', '12345', isSecure: true),
  //   SubscriptionType.starter,
  //   production: ProjectEnvironmentData('prod-starter-key', '12345', isSecure: true),
  // );

  test('add Peer', () async {
    final realtime = initRealtime(starterProject);
    realtime.addPeer(PeerMock());
    expect(realtime.connectedPeers.length, 1);
  });

  test('remove Peer', () async {
    final realtime = initRealtime(starterProject);
    when(realtime.userRpcs.getUserById.request(any)).thenAnswer((_) async => UserData('1'));
    final peer = PeerMock();
    realtime.addPeer(peer);
    await realtime.registerUser(Parameters('registerUser', <String, String>{'id': '1'}), peer);
    await realtime.removePeer(peer);
    expect(realtime.connectedUsers.length, 0);
    expect(realtime.connectedPeers.length, 0);
  });

  group('development', () {
    Realtime realtime;

    setUpAll(() {
      realtime = initRealtime(ProjectsData(ProjectEnvironmentData('dev-key', 'dev-secret')));
    });

    group('register user', () {
      test('isSecure false', () async {
        final realtime = initRealtime(starterProject);
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        expect(realtime.connectedUsers.length, 1);
      });

      group('secure', () {
        Realtime realtime;

        setUpAll(() {
          realtime = initRealtime(ProjectsData(ProjectEnvironmentData('dev-key', 'dev-secret', isSecure: true)));
        });

        test('valid signature', () async {
          final peer = PeerMock();
          realtime.addPeer(peer);
          final signature = sha512.convert(utf8.encode('1dev-secret')).toString();
          await realtime.registerUser(Parameters('registerUser', {'id': '1', 'signature': signature}), peer);
          expect(realtime.connectedUsers.length, 1);
        });

        test('invalid signature', () async {
          final peer = PeerMock();
          realtime.addPeer(peer);
          final signature = sha512.convert(utf8.encode('1123456')).toString();
          try {
            await realtime.registerUser(Parameters('registerUser', {'id': '1', 'signature': signature}), peer);
            expect(true, isFalse);
          } on RpcException catch (e) {
            expect(e.code, HttpStatus.unauthorized);
          }
        });
      });
    });

    group('get conversations', () {
      Realtime realtime;

      setUpAll(() {
        realtime = initRealtime(starterProject);
      });

      test('user with no conversations', () async {
        when(realtime.getConversationsForUser.request(any)).thenAnswer((_) async => []);
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        final conversations = await realtime.getConversations(peer);
        expect(conversations, isEmpty);
      });

      group('user with conversations', () {
        test('without messages', () async {
          when(realtime.getConversationsForUser.request(any)).thenAnswer(
            (_) async => [
              ConversationData(
                  id: '1', subject: null, avatar: null, admins: [UserData('1')], users: [UserData('1'), UserData('2')], messages: [], isGroup: false),
            ],
          );
          final peer = PeerMock();
          realtime.addPeer(peer);
          await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
          final conversations = await realtime.getConversations(peer);
          expect(conversations, isNotEmpty);
          expect(conversations.length, 1);
          expect(
              DeepCollectionEquality().equals(conversations, [
                {
                  'id': '1',
                  'admins': [
                    {'id': '1'}
                  ],
                  'users': [
                    {'id': '1'},
                    {'id': '2'}
                  ],
                  'messages': <dynamic>[],
                  'isGroup': false
                }
              ]),
              isTrue);
        });

        test('with messages', () async {
          when(realtime.getConversationsForUser.request(any)).thenAnswer(
            (_) async => [
              ConversationData(
                  id: '1',
                  subject: null,
                  avatar: null,
                  admins: [UserData('1')],
                  users: [UserData('1'), UserData('2')],
                  messages: [
                    MessageData(
                      '1',
                      'key',
                      '1',
                      '1',
                      'Hello',
                      DateTime.utc(2020, 01, 01, 14, 30),
                      [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.sent)],
                    ),
                  ],
                  isGroup: false),
            ],
          );
          final peer = PeerMock();
          realtime.addPeer(peer);
          await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
          final conversations = await realtime.getConversations(peer);
          print(conversations);
          expect(conversations, isNotEmpty);
          expect(conversations.length, 1);
          expect(
              DeepCollectionEquality().equals(conversations, [
                {
                  'id': '1',
                  'admins': [
                    {'id': '1'}
                  ],
                  'users': [
                    {'id': '1'},
                    {'id': '2'}
                  ],
                  'messages': [
                    {
                      'id': '1',
                      'senderId': '1',
                      'text': 'Hello',
                      'createdAt': '2020-01-01T14:30:00.000Z',
                      'statusDetails': [
                        {'id': '2', 'status': 'sent'}
                      ],
                      'status': 'sent'
                    }
                  ],
                  'isGroup': false
                }
              ]),
              isTrue);
        });
      });
    });

    group('update conversation', () {
      Realtime realtime;

      setUpAll(() {
        realtime = initRealtime(starterProject);
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
          expect(true, isFalse);
        } on RpcException catch (e) {
          expect(e.code, INVALID_PARAMS);
        }
      });

      test('with invalid conversationId', () async {
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        try {
          await realtime.setConversationOptions(
            Parameters(
              'setConversationOptions',
              <String, dynamic>{
                'conversationId': '404',
                'subject': 'Test',
              },
            ),
            peer,
          );
          expect(true, isFalse);
        } on RpcException catch (e) {
          expect(e.code, HttpStatus.notFound);
          expect(e.message, 'Conversation not found');
          expect((e.data as Map<String, dynamic>).containsKey('id'), isTrue);
          expect((e.data as Map<String, dynamic>)['id'], '404');
        }
      });

      test('with valid conversationId', () async {
        when(realtime.getConversationById.request(any))
            .thenAnswer((_) async => ConversationData(id: '1', subject: null, avatar: null, admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
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

      test('where i am not an admin', () async {
        when(realtime.getConversationById.request(any))
            .thenAnswer((_) async => ConversationData(id: '1', subject: null, avatar: null, admins: [UserData('2')], users: [UserData('1'), UserData('2')]));
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
          expect(true, isFalse);
        } on RpcException catch (e) {
          expect(e.code, HttpStatus.unauthorized);
        }
      });
    });

    group('get or create conversation', () {
      test('without conversationId in parameters', () async {
        final realtime = initRealtime(starterProject);
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
          expect(true, isTrue);
        } on RpcException catch (e) {
          expect(e.code, INVALID_PARAMS);
        }
      });

      test('get conversation', () async {
        final realtime = initRealtime(starterProject);
        when(realtime.getConversationById.request(any)).thenAnswer((_) async => ConversationData(
            id: '1',
            admins: [UserData('1')],
            users: [UserData('1'), UserData('2')],
            messages: [
              MessageData('1', starterProject.development.key, '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
                  [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.sent)])
            ],
            isGroup: false));
        when(realtime.userRpcs.getUserById.request(any)).thenAnswer((_) async => UserData('1'));
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        final other = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        final conversation = await realtime.getOrCreateConversation(
          Parameters(
            'getOrCreateConversation',
            <String, dynamic>{
              'id': '1',
            },
          ),
          peer,
        );
        expect(
            DeepCollectionEquality().equals(conversation, {
              'id': '1',
              'admins': [
                {'id': '1'}
              ],
              'users': [
                {'id': '1'},
                {'id': '2'}
              ],
              'messages': [
                {
                  'id': '1',
                  'senderId': '1',
                  'text': 'Hello world',
                  'createdAt': '2020-01-01T14:30:00.000Z',
                  'statusDetails': [
                    {'id': '2', 'status': 'sent'}
                  ],
                  'status': 'sent'
                }
              ],
              'isGroup': false
            }),
            isTrue);
        verifyNever(other.sendRequest('onConversationCreated', any));
      });

      test('get conversation when i am not a user', () async {
        final realtime = initRealtime(starterProject);
        when(realtime.getConversationById.request(any))
            .thenAnswer((_) async => ConversationData(id: '1', admins: [UserData('1')], users: [UserData('1'), UserData('2')], messages: [], isGroup: false));
        when(realtime.userRpcs.getUserById.request(any)).thenAnswer((_) async => UserData('12'));

        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '12'}), peer);
        try {
          await realtime.getOrCreateConversation(
            Parameters(
              'getOrCreateConversation',
              <String, dynamic>{
                'id': '1',
              },
            ),
            peer,
          );
          expect(true, isFalse);
        } on RpcException catch (e) {
          expect(e.code, HttpStatus.unauthorized);
          expect(e.message, 'Not authorized');
        }
      });

      test('exceed group limit', () async {
        final realtime = initRealtime(starterProject);
        when(realtime.getConversationById.request(any)).thenAnswer((_) async => null);
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters('dev-key', '1'))).thenAnswer((_) async => UserData('1'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters('dev-key', '2'))).thenAnswer((_) async => UserData('2'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters('dev-key', '3'))).thenAnswer((_) async => UserData('3'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters('dev-key', '4'))).thenAnswer((_) async => UserData('4'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters('dev-key', '5'))).thenAnswer((_) async => UserData('5'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters('dev-key', '6'))).thenAnswer((_) async => UserData('6'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters('dev-key', '7'))).thenAnswer((_) async => UserData('7'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters('dev-key', '8'))).thenAnswer((_) async => UserData('8'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters('dev-key', '9'))).thenAnswer((_) async => UserData('9'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters('dev-key', '10'))).thenAnswer((_) async => UserData('10'));
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(
            Parameters(
              'registerUser',
              {
                'id': '1',
              },
            ),
            peer);
        final response = await realtime.getOrCreateConversation(
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
        expect(
            DeepCollectionEquality().equals(response, {
              'id': '404',
              'admins': [
                {'id': '1'}
              ],
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
                {'id': '10'}
              ],
              'messages': <dynamic>[],
              'isGroup': false
            }),
            isTrue);
      });

      test('create group', () async {
        final realtime = initRealtime(starterProject);
        when(realtime.getConversationById.request(any)).thenAnswer((_) async => null);
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters(starterProject.development.key, '1'))).thenAnswer((_) async => UserData('1'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters(starterProject.development.key, '2'))).thenAnswer((_) async => UserData('2'));
        final peer = PeerMock();
        realtime.addPeer(peer);
        final other = PeerMock();
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        await realtime.getOrCreateConversation(
          Parameters(
            'getOrCreateConversation',
            <String, dynamic>{
              'id': '1',
              'users': [
                {'id': '1'},
                {'id': '2'},
                {'id': '3'},
              ],
            },
          ),
          peer,
        );
        verify(other.sendRequest('onConversationCreated', any)).called(1);
      });

      test('create 1:1', () async {
        final realtime = initRealtime(starterProject);
        when(realtime.getConversationById.request(any)).thenAnswer((_) async => null);
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters(starterProject.development.key, '1'))).thenAnswer((_) async => UserData('1'));
        when(realtime.userRpcs.getUserById.request(GetUserByIdParameters(starterProject.development.key, '2'))).thenAnswer((_) async => UserData('2'));
        final peer = PeerMock();
        realtime.addPeer(peer);
        final other = PeerMock();
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        final response = await realtime.getOrCreateConversation(
          Parameters(
            'getOrCreateConversation',
            <String, dynamic>{
              'id': '1',
              'users': [
                {'id': '1'},
                {'id': '2'},
              ],
            },
          ),
          peer,
        );
        verifyNever(other.sendRequest('onConversationCreated', any));
        expect(
            DeepCollectionEquality().equals(response, {
              'id': '1',
              'admins': [
                {'id': '1'}
              ],
              'users': [
                {'id': '1'},
                {'id': '2'}
              ],
              'messages': <dynamic>[],
              'isGroup': false
            }),
            isTrue);
      });
    });

    group('get messages', () {
      test('bad conversation id', () async {
        final realtime = initRealtime(starterProject);
        try {
          final peer = PeerMock();
          await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
          await realtime.getMessages(Parameters('getMessages', {'conversationId': '404'}), peer);
          expect(true, isTrue);
        } on RpcException catch (e) {
          expect(e.code, HttpStatus.notFound);
          expect(e.message, 'Conversation not found');
          expect(e.data, {'id': '404'});
        }
      });

      test('bad value of from and to', () async {
        final realtime = initRealtime(starterProject);
        final peer = PeerMock();
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        try {
          await realtime.getMessages(Parameters('getMessages', {'from': 0, 'to': 10, 'conversationId': '1'}), peer);
          expect(true, isFalse);
        } on RpcException catch (e) {
          expect(e.code, INVALID_PARAMS);
          expect(e.message, 'to can\'t be inferior at from');
        }
      });

      test('when i am not in the conversation', () async {
        final realtime = initRealtime(starterProject);
        when(realtime.getConversationById.request(any)).thenAnswer((_) async => ConversationData(id: '1', admins: [UserData('1')], users: [UserData('2')]));
        final peer = PeerMock();
        await realtime.registerUser(Parameters('registerUser', {'id': '12'}), peer);
        try {
          await realtime.getMessages(Parameters('getMessages', {'conversationId': '1'}), peer);
          expect(true, isFalse);
        } on RpcException catch (e) {
          expect(e.code, HttpStatus.unauthorized);
          expect(e.message, 'Not authorized');
        }
      });

      test('get all message', () async {
        final realtime = initRealtime(starterProject);
        when(realtime.getConversationById.request(any)).thenAnswer(
          (_) async => ConversationData(
            id: '1',
            admins: [UserData('1')],
            users: [UserData('1'), UserData('2')],
            messages: [
              MessageData('1', starterProject.development.key, '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
                  [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.sent)])
            ],
          ),
        );
        final peer = PeerMock();
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        final response = await realtime.getMessages(Parameters('getMessages', {'conversationId': '1'}), peer);
        expect(
            DeepCollectionEquality().equals(response, [
              {
                'id': '1',
                'senderId': '1',
                'text': 'Hello world',
                'createdAt': '2020-01-01T14:30:00.000Z',
                'statusDetails': [
                  {'id': '2', 'status': 'sent'}
                ],
                'status': 'sent'
              }
            ]),
            isTrue);
      });
    });

    group('get conversation details', () {
      Realtime realtime;

      setUpAll(() {
        realtime = initRealtime(starterProject);
      });

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
        when(realtime.getConversationById.request(any)).thenAnswer((_) async => ConversationData(id: '1', admins: [
              UserData('1')
            ], users: [
              UserData('1'),
              UserData('2')
            ], messages: [
              MessageData('1', starterProject.development.key, '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30), [
                MessageStatusByUserData('1', MessageStatus.seen),
                MessageStatusByUserData('2', MessageStatus.sent),
              ])
            ]));
        final peer = PeerMock();
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        final response = await realtime.getConversationDetail(Parameters('getConversationDetails', {'id': '1'}), peer);
        expect(
            DeepCollectionEquality().equals(response, {
              'id': '1',
              'admins': [
                {'id': '1'}
              ],
              'users': [
                {'id': '1'},
                {'id': '2'}
              ],
              'messages': [
                {
                  'id': '1',
                  'senderId': '1',
                  'text': 'Hello world',
                  'createdAt': '2020-01-01T14:30:00.000Z',
                  'statusDetails': [
                    {'id': '2', 'status': 'sent'}
                  ],
                  'status': 'sent',
                }
              ],
              'isGroup': false
            }),
            isTrue);
      });

      test('when i am not in the conversation', () async {
        when(realtime.getConversationById.request(any)).thenAnswer((_) async => ConversationData(id: '1', admins: [
              UserData('1')
            ], users: [
              UserData('1'),
              UserData('2')
            ], messages: [
              MessageData('1', starterProject.development.key, '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30), [
                MessageStatusByUserData('1', MessageStatus.seen),
                MessageStatusByUserData('2', MessageStatus.sent),
              ])
            ]));
        final peer = PeerMock();
        await realtime.registerUser(Parameters('registerUser', {'id': '12'}), peer);
        try {
          await realtime.getConversationDetail(Parameters('getConversationDetails', {'id': '1'}), peer);
          expect(true, isFalse);
        } on RpcException catch (e) {
          expect(e.code, HttpStatus.unauthorized);
          expect(e.message, 'Not authorized');
        }
      });
    });

    group('send message', () {
      Realtime realtime;

      setUpAll(() {
        realtime = initRealtime(starterProject);
      });

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

      test('send message to a conversation i am not in', () async {
        when(realtime.getConversationById.request(any))
            .thenAnswer((_) async => ConversationData(id: '1', admins: [UserData('1')], users: [UserData('2')], messages: []));
        when(realtime.getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
        final peer = PeerMock();
        realtime..addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '3'}), peer);
        try {
          await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '1', 'text': 'Hello world'}), peer);
          expect(true, isFalse);
        } on RpcException catch (e) {
          expect(e.code, HttpStatus.unauthorized);
          expect(e.message, 'Not authorized');
        }
      });

      group('1:1 conversation', () {
        test('when other is connected', () async {
          when(realtime.getConversationById.request(any))
              .thenAnswer((_) async => ConversationData(id: '1', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
          when(realtime.getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
          final peer = PeerMock();
          final other = PeerMock();
          realtime..addPeer(peer)..addPeer(other);
          await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
          await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
          final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '1', 'text': 'Hello world'}), peer);
          expect(response.isNotEmpty, isTrue);
          expect(
            DeepCollectionEquality().equals(response, {
              'id': '4',
              'senderId': '1',
              'text': 'Hello world',
              'createdAt': '2020-01-01T14:30:00.000Z',
              'statusDetails': [
                {'id': '2', 'status': 'sent'},
              ],
              'status': 'sent',
            }),
            isTrue,
          );
          verify(other.sendRequest('onConversationCreated', any)).called(1);
          verifyNever(other.sendRequest('receiveMessage1', any));
        });

        test('when other is not connected', () async {
          when(realtime.getConversationById.request(any))
              .thenAnswer((_) async => ConversationData(id: '1', admins: [UserData('1')], users: [UserData('1'), UserData('2')], messages: []));
          when(realtime.getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
          final peer = PeerMock();
          final other = PeerMock();
          realtime..addPeer(peer);
          await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
          final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '1', 'text': 'Hello world'}), peer);
          expect(response.isNotEmpty, isTrue);
          verifyNever(other.sendRequest('onConversationCreated', any));
          verifyNever(other.sendRequest('receiveMessage1', any));
          expect(
            DeepCollectionEquality().equals(response, {
              'id': '87',
              'senderId': '1',
              'text': 'Hello world',
              'createdAt': '2020-01-01T14:30:00.000Z',
              'status': 'sent',
              'statusDetails': [
                {'id': '2', 'status': 'sent'},
              ]
            }),
            isTrue,
          );
        });
      });

      group('group', () {
        test('first message in group conversation', () async {
          when(realtime.getConversationById.request(any)).thenAnswer((_) async => ConversationData(
                id: '1',
                admins: [UserData('1')],
                users: [UserData('1'), UserData('2'), UserData('3')],
              ));
          when(realtime.getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
          final peer = PeerMock();
          final other1 = PeerMock();
          final other2 = PeerMock();
          realtime..addPeer(peer)..addPeer(other1)..addPeer(other2);
          await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
          await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other1);
          await realtime.registerUser(Parameters('registerUser', {'id': '3'}), other2);
          final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '1', 'text': 'Hello world'}), peer);
          expect(response.isNotEmpty, isTrue);
          verifyNever(other1.sendRequest('onConversationCreated', any));
          verify(other1.sendRequest('receiveMessage1', any)).called(1);
          verify(other2.sendRequest('receiveMessage1', any)).called(1);
          verifyNever(realtime.httpClient.post(any, body: anyNamed('body')));
          expect(
            DeepCollectionEquality().equals(response, {
              'id': '95',
              'senderId': '1',
              'text': 'Hello world',
              'createdAt': '2020-01-01T14:30:00.000Z',
              'status': 'sent',
              'statusDetails': [
                {'id': '2', 'status': 'sent'},
                {'id': '3', 'status': 'sent'}
              ]
            }),
            isTrue,
          );
        });
      });

      test('with webHook == null', () async {
        final realtime = initRealtime(ProjectsData(ProjectEnvironmentData('add-peer-key', '12345')));
        when(realtime.getConversationById.request(any)).thenAnswer((_) async => ConversationData(
              id: '1',
              admins: [UserData('1')],
              users: [UserData('1'), UserData('2')],
            ));
        when(realtime.getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
        final peer = PeerMock();
        final other = PeerMock();
        realtime..addPeer(peer)..addPeer(other);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '1', 'text': 'Hello world'}), peer);
        expect(response.isNotEmpty, isTrue);
        verify(other.sendRequest('onConversationCreated', any)).called(1);
        verifyNever(other.sendRequest('receiveMessage1', any));
        verifyNever(realtime.httpClient.post(any, body: anyNamed('body')));
        expect(
          DeepCollectionEquality().equals(response, {
            'id': '4',
            'senderId': '1',
            'text': 'Hello world',
            'createdAt': '2020-01-01T14:30:00.000Z',
            'status': 'sent',
            'statusDetails': [
              {'id': '2', 'status': 'sent'},
            ]
          }),
          isTrue,
        );
      });

      test('with webHook != null', () async {
        final realtime = initRealtime(ProjectsData(
          ProjectEnvironmentData('add-peer-key', '12345', webHook: 'test.fr'),
        ));
        when(realtime.getConversationById.request(any)).thenAnswer((_) async => ConversationData(
              id: '1',
              admins: [UserData('1')],
              users: [UserData('1'), UserData('2')],
            ));
        when(realtime.getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
        final peer = PeerMock();
        final other = PeerMock();
        realtime..addPeer(peer)..addPeer(other);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '1', 'text': 'Hello world'}), peer);
        expect(response.isNotEmpty, isTrue);
        verify(other.sendRequest('onConversationCreated', any)).called(1);
        verifyNever(other.sendRequest('receiveMessage1', any));
        verify(realtime.httpClient.post(any, body: anyNamed('body'))).called(1);
        expect(
          DeepCollectionEquality().equals(response, {
            'id': '4',
            'senderId': '1',
            'text': 'Hello world',
            'createdAt': '2020-01-01T14:30:00.000Z',
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
        when(realtime.getMessageById.request(any)).thenAnswer((_) async => null);
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
        when(realtime.getMessageById.request(any)).thenAnswer((_) async => MessageData('1', '1', '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
            [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.seen)]));
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        await realtime.updateMessageStatus(Parameters('updateMessageStatus', {'id': '1', 'status': messageStatusToString(MessageStatus.sent)}), peer);
        verifyNever(peer.sendRequest(any));
      });

      test('sent to seen', () async {
        when(realtime.getMessageById.request(any)).thenAnswer((_) async => MessageData('1', '1', '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
            [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.sent)]));
        when(realtime.updateMessageStatusRpc.request(any)).thenAnswer((_) async => MessageData('1', '1', '1', '1', 'Hello world',
            DateTime.utc(2020, 01, 01, 14, 30), [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.seen)]));
        when(realtime.getConversationById.request(any))
            .thenAnswer((_) async => ConversationData(id: '1', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        final other = PeerMock();
        realtime.addPeer(other);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        await realtime.updateMessageStatus(
            Parameters('updateMessageStatus', <String, dynamic>{'id': '2', 'status': messageStatusToString(MessageStatus.seen)}), other);
        verify(peer.sendRequest('updateMessageStatus1', {
          'id': '1',
          'senderId': '1',
          'text': 'Hello world',
          'createdAt': '2020-01-01T14:30:00.000Z',
          'status': 'seen',
          'statusDetails': [
            {'id': '2', 'status': 'seen'}
          ]
        })).called(1);
      });

      test('sent to seen send only to user in conversation', () async {
        when(realtime.getMessageById.request(any)).thenAnswer((_) async => MessageData('1', '1', '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
            [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.sent)]));
        when(realtime.updateMessageStatusRpc.request(any)).thenAnswer((_) async => MessageData('1', '1', '1', '1', 'Hello world',
            DateTime.utc(2020, 01, 01, 14, 30), [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.seen)]));
        when(realtime.getConversationById.request(any))
            .thenAnswer((_) async => ConversationData(id: '1', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
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
        verifyNever(other1.sendRequest('updateMessageStatus1', any));
        verify(peer.sendRequest('updateMessageStatus1', any)).called(1);
      });

      test('seen to seen', () async {
        when(realtime.getMessageById.request(any)).thenAnswer((_) async => MessageData('1', '1', '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
            [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.seen)]));
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        final other = PeerMock();
        realtime.addPeer(other);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        await realtime.updateMessageStatus(Parameters('updateMessageStatus', {'id': '2', 'status': messageStatusToString(MessageStatus.seen)}), other);
        verifyNever(peer.sendRequest('updateMessageStatus1', any));
      });

      test('update message where i am not in the conversation', () async {
        when(realtime.getMessageById.request(any)).thenAnswer((_) async => MessageData('1', '1', '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
            [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.sent)]));
        when(realtime.updateMessageStatusRpc.request(any)).thenAnswer((_) async => MessageData('1', '1', '1', '1', 'Hello world',
            DateTime.utc(2020, 01, 01, 14, 30), [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.seen)]));
        when(realtime.getConversationById.request(any))
            .thenAnswer((_) async => ConversationData(id: '1', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        final other = PeerMock();
        realtime.addPeer(other);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        final other1 = PeerMock();
        realtime.addPeer(other1);
        await realtime.registerUser(Parameters('registerUser', {'id': '3'}), other1);
        try {
          await realtime.updateMessageStatus(
              Parameters('updateMessageStatus', <String, dynamic>{'id': '3', 'status': messageStatusToString(MessageStatus.seen)}), other1);
          expect(true, isFalse);
        } on RpcException catch (e) {
          expect(e.code, HttpStatus.unauthorized);
        }
      });
    });

    group('update message', () {
      test('message not found', () async {
        when(realtime.getMessageById.request(any)).thenAnswer((_) async => null);
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        try {
          await realtime.updateMessage(Parameters('updateMessage', {'id': '1', 'text': 'update text'}), peer);
        } on RpcException catch (e) {
          expect(e.code, HttpStatus.notFound);
        }
      });

      test('update text when i am not the sender', () async {
        when(realtime.getMessageById.request(any)).thenAnswer(
          (_) async => MessageData('1', '1', '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
              [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.sent)]),
        );
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '5'}), peer);
        try {
          await realtime.updateMessage(Parameters('updateMessage', {'id': '1', 'text': 'updated text'}), peer);
          expect(true, isFalse);
        } on RpcException catch (e) {
          expect(e.code, HttpStatus.unauthorized);
        }
      });

      test('update text', () async {
        when(realtime.getMessageById.request(any)).thenAnswer(
          (_) async => MessageData('1', '1', '1', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
              [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.sent)]),
        );
        when(realtime.updateMessageRpc.request(any)).thenAnswer(
          (_) async => MessageData('1', '1', '1', '1', 'updated text', DateTime.utc(2020, 01, 01, 14, 30),
              [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.sent)],
              modifiedAt: DateTime(2020, 01, 01, 14, 30)),
        );
        when(realtime.getConversationById.request(any))
            .thenAnswer((_) async => ConversationData(id: '1', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
        final peer = PeerMock();
        realtime.addPeer(peer);
        await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
        final other = PeerMock();
        realtime.addPeer(other);
        await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
        final response = await realtime.updateMessage(Parameters('updateMessage', {'id': '1', 'text': 'updated text'}), peer);
        expect(
            DeepCollectionEquality().equals(response, {
              'id': '1',
              'senderId': '1',
              'text': 'updated text',
              'createdAt': '2020-01-01T14:30:00.000Z',
              'statusDetails': [
                {'id': '2', 'status': 'sent'}
              ],
              'modifiedAt': '2020-01-01T14:30:00.000',
              'status': 'sent'
            }),
            true);
        verify(other.sendRequest('updateMessage1', any)).called(1);
      });
    });
  });

  group('production', () {
    Realtime starter;
    Realtime complete;

    setUpAll(() {
      starter = initRealtime(
        ProjectsData(
          ProjectEnvironmentData('dev-key', 'dev-secret'),
          production: ProjectEnvironmentData('prod-key', 'prod-secret', isSecure: true, webHook: 'test.fr'),
        ),
      );
      complete = initRealtime(
        ProjectsData(
          ProjectEnvironmentData('dev-key', 'dev-secret'),
          production: ProjectEnvironmentData('prod-key', 'prod-secret', isSecure: true, webHook: 'test.fr'),
          subscriptionType: SubscriptionType.complete,
        ),
      );
    });

    group('starter', () {
      group('get or create conversation', () {
        test('exceed group limit', () async {
          when(starter.getConversationById.request(any)).thenAnswer((_) async => null);
          when(starter.userRpcs.getUserById.request(any)).thenAnswer((_) async => UserData('1'));
          final peer = PeerMock();
          starter.addPeer(peer);
          final signature = sha512.convert(utf8.encode('1prod-secret')).toString();
          await starter.registerUser(Parameters('registerUser', {'id': '1', 'signature': signature}), peer);
          try {
            await starter.getOrCreateConversation(
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
      });

      group('send message', () {
        test('with webhook', () async {
          final realtime = initRealtime(starterProject);
          when(realtime.getConversationById.request(any)).thenAnswer((_) async => ConversationData(
                id: '1',
                admins: [UserData('1')],
                users: [UserData('1'), UserData('2')],
              ));
          when(realtime.getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
          final peer = PeerMock();
          final other = PeerMock();
          realtime..addPeer(peer)..addPeer(other);
          await realtime.registerUser(Parameters('registerUser', {'id': '1'}), peer);
          await realtime.registerUser(Parameters('registerUser', {'id': '2'}), other);
          final response = await realtime.sendMessage(Parameters('sendMessage', {'conversationId': '1', 'text': 'Hello world'}), peer);
          expect(response.isNotEmpty, isTrue);
          verify(other.sendRequest('onConversationCreated', any)).called(1);
          verifyNever(other.sendRequest('receiveMessage1', any));
          verifyNever(realtime.httpClient.post(any, body: anyNamed('body')));
          expect(
            DeepCollectionEquality().equals(response, {
              'id': '4',
              'senderId': '1',
              'text': 'Hello world',
              'createdAt': '2020-01-01T14:30:00.000Z',
              'status': 'sent',
              'statusDetails': [
                {'id': '2', 'status': 'sent'},
              ]
            }),
            isTrue,
          );
        });
      });
    });

    group('complete', () {
      group('send message', () {
        test('with webhook', () async {
          when(complete.getConversationById.request(any)).thenAnswer((_) async => ConversationData(
                id: '1',
                admins: [UserData('1')],
                users: [UserData('1'), UserData('2')],
              ));
          when(complete.getNumberOfMessageForConversation.request(any)).thenAnswer((_) async => 0);
          final peer = PeerMock();
          final other = PeerMock();
          complete..addPeer(peer)..addPeer(other);
          final signaturePeer = sha512.convert(utf8.encode('1prod-secret')).toString();
          final signatureOther = sha512.convert(utf8.encode('2prod-secret')).toString();
          await complete.registerUser(Parameters('registerUser', {'id': '1', 'signature': signaturePeer}), peer);
          await complete.registerUser(Parameters('registerUser', {'id': '2', 'signature': signatureOther}), other);
          final response = await complete.sendMessage(Parameters('sendMessage', {'conversationId': '1', 'text': 'Hello world'}), peer);
          expect(response.isNotEmpty, isTrue);
          verify(other.sendRequest('onConversationCreated', any)).called(1);
          verifyNever(other.sendRequest('receiveMessage1', any));
          verify(complete.httpClient.post(any, body: anyNamed('body'))).called(1);
          expect(
            DeepCollectionEquality().equals(response, {
              'id': '4',
              'senderId': '1',
              'text': 'Hello world',
              'createdAt': '2020-01-01T14:30:00.000Z',
              'status': 'sent',
              'statusDetails': [
                {'id': '2', 'status': 'sent'},
              ]
            }),
            isTrue,
          );
        });
      });
    });
  });
}
