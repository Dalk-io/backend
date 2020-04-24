import 'dart:convert';

import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/rpc/conversations/get_conversations_for_user.dart';
import 'package:backend/src/rpc/conversations/parameters.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/mocks/databases/conversations/get_user_conversations.dart';
import 'src/mocks/rpc/user/get_user_by_id.dart';

void main() {
  test('get user conversations rpc when no conversation', () async {
    final parameters = GetConversationsForUserParameters('toto', '12345');
    final getUserConversationDatabase = GetConversationsForUserFromDatabaseMock();
    when(getUserConversationDatabase.request(parameters)).thenAnswer((_) async => <List>[]);
    final getUserById = GetUserByIdMock();
    final getUserConversations = GetConversationsForUser(getUserConversationDatabase, null, getUserById);
    final conversations = await getUserConversations.request(parameters);
    expect(conversations, isEmpty);
  });

  test('get user conversations rpc when one conversation and no message', () async {
    final parameters = GetConversationsForUserParameters('toto', '12345');
    final getUserConversationFromDatabase = GetConversationsForUserFromDatabaseMock();
    final getLastMessageForConversationFromDatabase = GetLastMessageForConversationFromDatabaseMock();
    when(getUserConversationFromDatabase.request(parameters)).thenAnswer((_) async => <List>[
          <dynamic>[
            '1',
            null,
            null,
            json.encode(['1']),
            json.encode(['1', '2']),
            false,
          ]
        ]);
    when(getLastMessageForConversationFromDatabase.request(GetLastMessageForConversationParameters('toto', '1', '12345'))).thenAnswer((_) async => <List>[]);
    final getUserById = GetUserByIdMock();
    final getUserConversations = GetConversationsForUser(getUserConversationFromDatabase, getLastMessageForConversationFromDatabase, getUserById);
    final conversations = await getUserConversations.request(parameters);
    expect(conversations, isNotEmpty);
    expect(conversations.length, 1);
    expect(conversations.first.messages.length, 0);
  });

  test('get user conversations rpc when one conversation and with one message', () async {
    final projectId = 'toto';
    final userId = '12345';
    final parameters = GetConversationsForUserParameters(projectId, userId);
    final getUserConversationFromDatabase = GetConversationsForUserFromDatabaseMock();
    final getLastMessageForConversationFromDatabase = GetLastMessageForConversationFromDatabaseMock();
    when(getUserConversationFromDatabase.request(parameters)).thenAnswer((_) async => <List>[
          <dynamic>[
            '1',
            null,
            null,
            json.encode(['1']),
            json.encode(['1', '2']),
            false,
          ]
        ]);
    when(getLastMessageForConversationFromDatabase.request(GetLastMessageForConversationParameters(projectId, '1', userId))).thenAnswer((_) async => <List>[
          <dynamic>[
            '1',
            projectId,
            '1',
            userId,
            'hello test',
            DateTime(2020, 01, 01),
            json.encode([
              {'id': '2', 'state': MessageState.seen.index},
              {'id': '2', 'state': MessageState.sent.index}
            ])
          ]
        ]);
    final getUserById = GetUserByIdMock();
    final getUserConversations = GetConversationsForUser(getUserConversationFromDatabase, getLastMessageForConversationFromDatabase, getUserById);
    final conversations = await getUserConversations.request(parameters);
    expect(conversations, isNotEmpty);
    expect(conversations.length, 1);
    expect(conversations.first.messages, isNotEmpty);
    expect(conversations.first.messages.length, 1);
    expect(conversations.first.messages.first.text, 'hello test');
    expect(conversations.first.messages.first.states.first.state, MessageState.seen);
  });
}
