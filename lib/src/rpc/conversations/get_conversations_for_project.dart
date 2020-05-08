import 'package:backend/backend.dart';
import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/databases/conversations/get_conversations_for_project.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/conversations/parameters.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:backend/src/utils/conversations_from_database.dart';

class GetConversationsForProject extends Endpoint<GetConversationsForProjectParamters, List<ConversationData>> {
  final GetConversationsForProjectFromDatabase _getConversationsForProjectFromDatabase;
  final GetUserById getUserById;
  final GetLastMessageForConversationFromDatabase getLastMessageForConversationFromDatabase;

  GetConversationsForProject(this._getConversationsForProjectFromDatabase, this.getUserById, this.getLastMessageForConversationFromDatabase);

  @override
  Future<List<ConversationData>> request(GetConversationsForProjectParamters input) async {
    final results = await _getConversationsForProjectFromDatabase.request(input.projectKey);
    var _conversationsData = await conversationsFromDatabase(results, input.projectKey, getUserById);
    if (input.from != null) {
      _conversationsData = _conversationsData.skipWhile((value) => value.id != input.from).toList();
    }
    if (input.take > -1) {
      _conversationsData = _conversationsData.take(input.take).toList();
    }
    final conversationsData = <ConversationData>[];
    for (final conversation in _conversationsData) {
      final messages = await getLastMessageForConversationFromDatabase.request(GetLastMessageForConversationParameters(input.projectKey, conversation.id));
      conversationsData.add(conversation.copyWith(messages: messages.map((message) => MessageData.fromDatabase(message)).toList()));
    }
    return conversationsData;
  }
}
