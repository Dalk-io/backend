import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/databases/message/get_message_by_id.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetMessageById extends Endpoint<GetMessageByIdParameters, MessageData> {
  final GetMessageByIdFromDatabase _getMessageByIdFromDatabase;

  GetMessageById(this._getMessageByIdFromDatabase);

  @override
  Future<MessageData> request(GetMessageByIdParameters input) async {
    final messageData = await _getMessageByIdFromDatabase.request(input);
    return MessageData.fromDatabase(messageData.first);
  }
}
