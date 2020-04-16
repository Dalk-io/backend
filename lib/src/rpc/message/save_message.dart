import 'package:backend/backend.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';

class SaveMessage extends Endpoint<SaveMessageParameters, int> {
  final SaveMessageToDatabase _saveMessageToDatabase;

  SaveMessage(this._saveMessageToDatabase);

  @override
  Future<int> request(SaveMessageParameters input) async {
    final result = await _saveMessageToDatabase.request(input);
    return result.first.first as int;
  }
}
