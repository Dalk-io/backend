import 'package:backend/src/databases/message/get_message_by_id.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/models/message.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetMessageById extends Endpoint<GetMessageByIdParameters, Message> {
  final GetMessageByIdFromDatabase _getMessageByIdFromDatabase;

  GetMessageById(this._getMessageByIdFromDatabase);

  @override
  Future<Message> request(GetMessageByIdParameters input) async {
    final messageData = await _getMessageByIdFromDatabase.request(input);
    return Message.fromDatabase(messageData.first);
  }
}
