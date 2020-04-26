import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/databases/messages/get_messages_for_conversation.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/messages/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetMessagesForConversation extends Endpoint<GetMessagesForConversationParameters, List<MessageData>> {
  final GetMessagesForConversationFromDatabase _getMessagesForConversationFromDatabase;

  GetMessagesForConversation(this._getMessagesForConversationFromDatabase);

  @override
  Future<List<MessageData>> request(GetMessagesForConversationParameters input) async {
    var messagesData = await _getMessagesForConversationFromDatabase.request(input);
    if (input.to > 0 && input.from < input.to) {
      messagesData = messagesData.skip(input.from).take(input.to - input.from).toList();
    }
    return messagesData.map((message) => MessageData.fromDatabase(message)).toList();
  }
}
