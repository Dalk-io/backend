import 'package:backend/backend.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class UpdateMessageState extends Endpoint<UpdateMessageStateParameters, MessageData> {
  final UpdateMessageStateToDatabase _updateMessageStateToDatabase;

  UpdateMessageState(this._updateMessageStateToDatabase);

  @override
  Future<MessageData> request(UpdateMessageStateParameters input) async {
    final result = await _updateMessageStateToDatabase.request(input);
    return MessageData.fromDatabase(result.first);
  }
}
