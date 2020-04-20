import 'package:backend/src/databases/token/save_token.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/token/parameters.dart';

class SaveToken extends Endpoint<SaveTokenParameters, void> {
  final SaveTokenToDatabase _saveTokenToDatabase;

  SaveToken(this._saveTokenToDatabase);

  @override
  Future<void> request(SaveTokenParameters input) async {
    await _saveTokenToDatabase.request(input);
  }
}
