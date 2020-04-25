import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/databases/conversations/get_conversations_for_user.dart';
import 'package:backend/src/databases/message/get_last_message_for_conversation.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/conversations/parameters.dart';
import 'package:backend/src/rpc/user/get_user_by_id.dart';
import 'package:backend/src/utils/conversations_from_database.dart';
import 'package:meta/meta.dart';

@immutable
class GetConversationsForUser extends Endpoint<GetConversationsForUserParameters, List<ConversationData>> {
  final GetConversationsForUserFromDatabase _getUserConversationDatabase;
  final GetLastMessageForConversationFromDatabase _getLastMessageForConversationFromDatabase;
  final GetUserById _getUserById;

  GetConversationsForUser(this._getUserConversationDatabase, this._getLastMessageForConversationFromDatabase, this._getUserById);

  @override
  Future<List<ConversationData>> request(GetConversationsForUserParameters input) async {
    final results = await _getUserConversationDatabase.request(input);
    return conversationsFromDatabase(results, input.projectId, _getUserById, _getLastMessageForConversationFromDatabase);
  }
}
