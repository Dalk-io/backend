import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/databases/message/update_message.dart';
import 'package:backend/src/endpoint.dart';
import 'package:meta/meta.dart';

@immutable
class UpdateMessage extends Endpoint<MessageData, MessageData> {
  final UpdateMessageToDatabase _updateMessageToDatabase;

  UpdateMessage(this._updateMessageToDatabase);

  @override
  Future<MessageData> request(MessageData input) async {
    final result = await _updateMessageToDatabase.request(input);
    return MessageData.fromDatabase(result.first);
  }
}
