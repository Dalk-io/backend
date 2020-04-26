import 'dart:convert';

import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/data/user/user.dart';
import 'package:backend/src/rpc/user/get_user_by_id.dart';
import 'package:backend/src/rpc/user/parameters.dart';

Future<List<ConversationData>> conversationsFromDatabase(
  List<List<dynamic>> conversationsData,
  String projectKey,
  GetUserById getUserById,
) async {
  final conversations = <ConversationData>[];
  for (final conversationData in conversationsData) {
    conversations.add(await conversationFromDatabase(conversationData, projectKey, getUserById));
  }
  return conversations;
}

Future<ConversationData> conversationFromDatabase(
  List<dynamic> conversationData,
  String projectKey,
  GetUserById getUserById,
) async {
  final admins = await _getUsersFromIds(getUserById, projectKey, (json.decode(conversationData[3] as String) as List).cast<String>());
  final users = await _getUsersFromIds(getUserById, projectKey, (json.decode(conversationData[4] as String) as List).cast<String>());
  return ConversationData(
    id: conversationData[0] as String,
    subject: conversationData[1] as String,
    avatar: conversationData[2] as String,
    admins: admins,
    users: users,
    messages: [],
    isGroup: conversationData[5] as bool,
  );
}

Future<List<UserData>> _getUsersFromIds(GetUserById getUserById, String projectId, List<String> userId) async {
  final users = <UserData>[];
  for (final user in userId) {
    users.add(await getUserById.request(GetUserByIdParameters(projectId, user)));
  }
  return users;
}
