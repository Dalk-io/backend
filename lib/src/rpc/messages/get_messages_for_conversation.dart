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
    var filteredMessagesData = messagesData.map((message) => Message.fromDatabase(message)).toList();
    if (filteredMessagesData.length > input.from) {
      filteredMessagesData = filteredMessagesData.skip(input.from).toList();
    }
    if (input.to != -1 && filteredMessagesData.length >= input.to - input.from) {
      filteredMessagesData = filteredMessagesData.take(input.to - input.from).toList();
    }
    return filteredMessagesData.toList();
  }
}
