import 'package:backend/src/databases/conversation/save_conversation.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class SaveConversation extends Endpoint<SaveConversationParameters, void> {
  final SaveConversationToDatabase _saveConversationToDatabase;

  SaveConversation(this._saveConversationToDatabase);

  @override
  Future<void> request(SaveConversationParameters input) async {
    await _saveConversationToDatabase.request(input);
  }
}
