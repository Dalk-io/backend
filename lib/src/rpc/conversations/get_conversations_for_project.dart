import 'package:backend/backend.dart';
import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/databases/conversations/get_conversations_for_project.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:backend/src/utils/conversations_from_database.dart';

class GetConversationsForProject extends Endpoint<String, List<ConversationData>> {
  final GetConversationsForProjectFromDatabase _getConversationsForProjectFromDatabase;
  final GetUserById getUserById;
  final GetLastMessageForConversationFromDatabase getLastMessageForConversationFromDatabase;

  GetConversationsForProject(this._getConversationsForProjectFromDatabase, this.getUserById, this.getLastMessageForConversationFromDatabase);

  @override
  Future<List<ConversationData>> request(String input) async {
    final results = await _getConversationsForProjectFromDatabase.request(input);
    final _conversationsData = await conversationsFromDatabase(results, input, getUserById);
    final conversationsData = <ConversationData>[];
    for (final conversation in _conversationsData) {
      final messages = await getLastMessageForConversationFromDatabase.request(GetLastMessageForConversationParameters(input, conversation.id));
      conversationsData.add(conversation.copyWith(messages: messages.map((message) => MessageData.fromDatabase(message)).toList()));
    }
    return conversationsData;
  }
}
