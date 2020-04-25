import 'package:backend/backend.dart';
import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/databases/conversations/get_conversations_for_project.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/utils/conversations_from_database.dart';

class GetConversationsForProject extends Endpoint<String, List<ConversationData>> {
  final GetConversationsForProjectFromDatabase _getConversationsForProjectFromDatabase;
  final GetUserById getUserById;
  final GetLastMessageForConversationFromDatabase getLastMessageForConversationFromDatabase;

  GetConversationsForProject(this._getConversationsForProjectFromDatabase, this.getUserById, this.getLastMessageForConversationFromDatabase);

  @override
  Future<List<ConversationData>> request(String input) async {
    final results = await _getConversationsForProjectFromDatabase.request(input);
    return conversationsFromDatabase(results, input, getUserById, getLastMessageForConversationFromDatabase);
  }
}
