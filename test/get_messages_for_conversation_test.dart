import 'package:backend/src/rpc/messages/get_messages_for_conversation.dart';
import 'package:backend/src/rpc/messages/parameters.dart';
import 'package:backend/src/utils/message_to_json.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/mocks/databases/messages/get_messages_for_conversation.dart';

void main() {
  test('basic request', () async {
    final getMessagesForConversationFromDatabase = GetMessagesForConversationFromDatabaseMock();
    when(getMessagesForConversationFromDatabase.request(any)).thenAnswer((_) async => <List>[
          <dynamic>[
            '1',
            'projectKey',
            'conversationId',
            '1',
            'Hello',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
          <dynamic>[
            '2',
            'projectKey',
            'conversationId',
            '1',
            'Hello world',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
        ]);
    final getMessagesForConversation = GetMessagesForConversation(getMessagesForConversationFromDatabase);
    final result = await getMessagesForConversation.request(GetMessagesForConversationParameters('test', 'test'));
    expect(
        DeepCollectionEquality().equals(result.map((e) => messageToJson(e)).toList(), [
          {
            'id': '1',
            'senderId': '1',
            'text': 'Hello',
            'createdAt': '2020-01-01T14:30:00.000',
            'statusDetails': <dynamic>[],
            'status': 'sent',
          }
        ]),
        true);
  });

  test('take all message', () async {
    final getMessagesForConversationFromDatabase = GetMessagesForConversationFromDatabaseMock();
    when(getMessagesForConversationFromDatabase.request(any)).thenAnswer((_) async => <List>[
          <dynamic>[
            '1',
            'projectKey',
            'conversationId',
            '1',
            'Hello',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
          <dynamic>[
            '2',
            'projectKey',
            'conversationId',
            '1',
            'Hello world',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
          <dynamic>[
            '3',
            'projectKey',
            'conversationId',
            '1',
            'Hello world 3',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
        ]);
    final getMessagesForConversation = GetMessagesForConversation(getMessagesForConversationFromDatabase);
    final result = await getMessagesForConversation.request(GetMessagesForConversationParameters('test', 'test', take: -1));
    expect(
        DeepCollectionEquality().equals(result.map((e) => messageToJson(e)).toList(), [
          {
            'id': '1',
            'senderId': '1',
            'text': 'Hello',
            'createdAt': '2020-01-01T14:30:00.000',
            'statusDetails': <dynamic>[],
            'status': 'sent',
          },
          {
            'id': '2',
            'senderId': '1',
            'text': 'Hello world',
            'createdAt': '2020-01-01T14:30:00.000',
            'statusDetails': <dynamic>[],
            'status': 'sent',
          },
          {
            'id': '3',
            'senderId': '1',
            'text': 'Hello world 3',
            'createdAt': '2020-01-01T14:30:00.000',
            'statusDetails': <dynamic>[],
            'status': 'sent',
          },
        ]),
        true);
  });

  test('skip and take one message', () async {
    final getMessagesForConversationFromDatabase = GetMessagesForConversationFromDatabaseMock();
    when(getMessagesForConversationFromDatabase.request(any)).thenAnswer((_) async => <List>[
          <dynamic>[
            '1',
            'projectKey',
            'conversationId',
            '1',
            'Hello',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
          <dynamic>[
            '2',
            'projectKey',
            'conversationId',
            '1',
            'Hello world',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
          <dynamic>[
            '3',
            'projectKey',
            'conversationId',
            '1',
            'Hello world 3',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
        ]);
    final getMessagesForConversation = GetMessagesForConversation(getMessagesForConversationFromDatabase);
    final result = await getMessagesForConversation.request(GetMessagesForConversationParameters('test', 'test', from: '2'));
    expect(
        DeepCollectionEquality().equals(result.map((e) => messageToJson(e)).toList(), [
          {
            'id': '2',
            'senderId': '1',
            'text': 'Hello world',
            'createdAt': '2020-01-01T14:30:00.000',
            'statusDetails': <dynamic>[],
            'status': 'sent',
          },
        ]),
        true);
  });

  test('skip and take all other message', () async {
    final getMessagesForConversationFromDatabase = GetMessagesForConversationFromDatabaseMock();
    when(getMessagesForConversationFromDatabase.request(any)).thenAnswer((_) async => <List>[
          <dynamic>[
            '1',
            'projectKey',
            'conversationId',
            '1',
            'Hello',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
          <dynamic>[
            '2',
            'projectKey',
            'conversationId',
            '1',
            'Hello world',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
          <dynamic>[
            '3',
            'projectKey',
            'conversationId',
            '1',
            'Hello world 3',
            DateTime(2020, 01, 01, 14, 30),
            '[{"id": "1", "status": 0}]',
            null,
            null,
          ],
        ]);
    final getMessagesForConversation = GetMessagesForConversation(getMessagesForConversationFromDatabase);
    final result = await getMessagesForConversation.request(GetMessagesForConversationParameters('test', 'test', from: '2', take: -1));
    expect(
        DeepCollectionEquality().equals(result.map((e) => messageToJson(e)).toList(), [
          {
            'id': '2',
            'senderId': '1',
            'text': 'Hello world',
            'createdAt': '2020-01-01T14:30:00.000',
            'statusDetails': <dynamic>[],
            'status': 'sent',
          },
          {
            'id': '3',
            'senderId': '1',
            'text': 'Hello world 3',
            'createdAt': '2020-01-01T14:30:00.000',
            'statusDetails': <dynamic>[],
            'status': 'sent',
          },
        ]),
        true);
  });
}
