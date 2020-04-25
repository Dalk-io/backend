import 'dart:convert';

import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/data/user/user.dart';
import 'package:backend/src/databases/conversations/get_conversations_for_user.dart';
import 'package:backend/src/databases/message/get_last_message_for_conversation.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/conversations/parameters.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:backend/src/rpc/user/get_user_by_id.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetConversationsForUser extends Endpoint<GetConversationsForUserParameters, List<ConversationData>> {
  final GetConversationsForUserFromDatabase _getUserConversationDatabase;
  final GetLastMessageForConversationFromDatabase _getLastMessageForConversation;
  final GetUserById _getUserById;

  GetConversationsForUser(this._getUserConversationDatabase, this._getLastMessageForConversation, this._getUserById);

  @override
  Future<List<ConversationData>> request(GetConversationsForUserParameters input) async {
    final conversationsData = await _getUserConversationDatabase.request(input);
    final conversations = <ConversationData>[];
    for (final conversationData in conversationsData) {
      final conversationId = conversationData[0] as String;
      final admins = await _getUsersFromIds(input.projectId, (json.decode(conversationData[3] as String) as List).cast<String>());
      final users = await _getUsersFromIds(input.projectId, (json.decode(conversationData[4] as String) as List).cast<String>());
      final messagesData = await _getLastMessageForConversation.request(GetLastMessageForConversationParameters(input.projectId, conversationId, input.userId));
      conversations.add(ConversationData(
        id: conversationData[0] as String,
        subject: conversationData[1] as String,
        avatar: conversationData[2] as String,
        admins: admins,
        users: users,
        messages: messagesData.map((messageData) => MessageData.fromDatabase(messageData).copyWith(projectId: null, conversationId: null)).toList(),
        isGroup: conversationData[5] as bool,
      ));
    }
    return conversations;
  }

  Future<List<UserData>> _getUsersFromIds(String projectId, List<String> userId) async {
    final users = <UserData>[];
    for (final user in userId) {
      users.add(await _getUserById.request(GetUserByIdParameters(projectId, user)));
    }
    return users;
  }
}
