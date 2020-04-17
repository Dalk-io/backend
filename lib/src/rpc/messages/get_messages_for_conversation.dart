import 'package:backend/backend.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/models/message.dart';
import 'package:backend/src/rpc/messages/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetMessagesForConversation extends Endpoint<GetMessagesForConversationParameters, List<Message>> {
  final GetMessagesForConversationFromDatabase _getMessagesForConversationFromDatabase;

  GetMessagesForConversation(this._getMessagesForConversationFromDatabase);

  @override
  Future<List<Message>> request(GetMessagesForConversationParameters input) async {
    final messagesData = await _getMessagesForConversationFromDatabase.request(input);
    return messagesData.map((message) => Message.fromDatabase(message)).toList();
  }
}
