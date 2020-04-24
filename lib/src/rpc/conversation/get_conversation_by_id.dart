import 'dart:convert';

import 'package:backend/backend.dart';
import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/data/user/user.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:backend/src/rpc/messages/get_messages_for_conversation.dart';
import 'package:backend/src/rpc/messages/parameters.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetConversationById extends Endpoint<GetConversationByIdParameters, ConversationData> {
  final GetConversationByIdFromDatabase _getConversationByIdFromDatabase;
  final GetMessagesForConversation _getMessagesForConversation;
  final GetUserById _getUserById;

  GetConversationById(this._getConversationByIdFromDatabase, this._getMessagesForConversation, this._getUserById);

  @override
  Future<ConversationData> request(GetConversationByIdParameters input) async {
    final conversationData = await _getConversationByIdFromDatabase.request(input);
    if (conversationData.isEmpty) {
      return null;
    }
    final result = conversationData.first;
    final admins = await _getUsersFromIds(input.projectId, (json.decode(result[3] as String) as List).cast<String>());
    final users = await _getUsersFromIds(input.projectId, (json.decode(result[4] as String) as List).cast<String>());
    final messages = <MessageData>[];
    if (input.getMessages) {
      messages.addAll(await _getMessagesForConversation.request(GetMessagesForConversationParameters(input.projectId, input.conversationId, from: 0, to: -1)));
    }
    final conversation = ConversationData(
      id: result[0] as String,
      subject: result[1] as String,
      avatar: result[2] as String,
      admins: admins,
      users: users,
      messages: messages,
      isGroup: result[5] as bool,
    );
    return conversation;
  }

  Future<List<UserData>> _getUsersFromIds(String projectId, List<String> userId) async {
    final users = <UserData>[];
    for (final user in userId) {
      users.add(await _getUserById.request(GetUserByIdParameters(projectId, user)));
    }
    return users;
  }
}
