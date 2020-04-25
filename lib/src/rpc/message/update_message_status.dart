import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/databases/message/update_message_status.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class UpdateMessageStatus extends Endpoint<UpdateMessageStatusParameters, MessageData> {
  final UpdateMessageStatusToDatabase _updateMessageStatusToDatabase;

  UpdateMessageStatus(this._updateMessageStatusToDatabase);

  @override
  Future<MessageData> request(UpdateMessageStatusParameters input) async {
    final result = await _updateMessageStatusToDatabase.request(input);
    return MessageData.fromDatabase(result.first);
  }
}
