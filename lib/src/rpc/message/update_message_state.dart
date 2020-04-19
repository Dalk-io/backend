import 'package:backend/backend.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/models/message.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class UpdateMessageState extends Endpoint<UpdateMessageStateParameters, Message> {
  final UpdateMessageStateToDatabase _updateMessageStateToDatabase;

  UpdateMessageState(this._updateMessageStateToDatabase);

  @override
  Future<Message> request(UpdateMessageStateParameters input) async {
    final result = await _updateMessageStateToDatabase.request(input);
    return Message.fromDatabase(result.first);
  }
}
