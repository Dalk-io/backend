import 'package:backend/src/databases/conversation/get_number_of_message_for_conversation.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetNumberOfMessageForConversation extends Endpoint<GetNumberOfMessageForConversationParameter, int> {
  final GetNumberOfMessageForConversationFromDatabase _getNumberOfMessageForConversationFromDatabase;

  GetNumberOfMessageForConversation(this._getNumberOfMessageForConversationFromDatabase);

  @override
  Future<int> request(GetNumberOfMessageForConversationParameter input) async {
    final result = await _getNumberOfMessageForConversationFromDatabase.request(input);
    return result.first.first as int;
  }
}
