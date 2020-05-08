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
    final _messagesData = await _getMessagesForConversationFromDatabase.request(input);
    var messagesData = _messagesData.map((e) => MessageData.fromDatabase(e)).toList();
    if (input.from != null) {
      messagesData = messagesData.skipWhile((value) => value.id != input.from).toList();
    }
    if (input.take > -1) {
      messagesData = messagesData.take(input.take).toList();
    }
    return messagesData.toList();
  }
}
