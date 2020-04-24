import 'package:backend/backend.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/messages/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetMessagesForConversation extends Endpoint<GetMessagesForConversationParameters, List<MessageData>> {
  final GetMessagesForConversationFromDatabase _getMessagesForConversationFromDatabase;

  GetMessagesForConversation(this._getMessagesForConversationFromDatabase);

  @override
  Future<List<MessageData>> request(GetMessagesForConversationParameters input) async {
    final messagesData = await _getMessagesForConversationFromDatabase.request(input);
    return messagesData.map((message) => MessageData.fromDatabase(message)).toList();
  }
}
