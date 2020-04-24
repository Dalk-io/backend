import 'package:backend/backend.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class SaveMessage extends Endpoint<SaveMessageParameters, void> {
  final SaveMessageToDatabase _saveMessageToDatabase;

  SaveMessage(this._saveMessageToDatabase);

  @override
  Future<void> request(SaveMessageParameters input) async {
    await _saveMessageToDatabase.request(input);
  }
}
