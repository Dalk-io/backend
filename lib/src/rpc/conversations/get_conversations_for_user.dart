import 'package:backend/src/databases/conversations/get_conversations_for_user.dart';
import 'package:backend/src/databases/message/get_last_message_for_conversation.dart';
import 'package:backend/src/models/conversation.dart';
import 'package:backend/src/models/message.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/conversations/parameters.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetConversationsForUser extends Endpoint<GetConversationsForUserParameters, List<Conversation>> {
  final GetConversationsForUserFromDatabase _getUserConversationDatabase;
  final GetLastMessageForConversationFromDatabase _getLastMessageForConversation;

  GetConversationsForUser(this._getUserConversationDatabase, this._getLastMessageForConversation);

  @override
  Future<List<Conversation>> request(GetConversationsForUserParameters input) async {
    final conversationsData = await _getUserConversationDatabase.request(input);
    final conversations = conversationsData.map((c) => Conversation.fromDatabase(c)).toList(growable: false);
    for (final conversation in conversations) {
      final messages = await _getLastMessageForConversation.request(GetLastMessageForConversationParameters(input.projectId, conversation.id, input.userId));
      if (messages.isNotEmpty) {
        conversation.messages.add(Message.fromDatabase(messages.first));
      }
    }
    return conversations;
  }
}
