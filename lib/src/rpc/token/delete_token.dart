import 'package:backend/src/databases/token/delete_token.dart';
import 'package:backend/src/endpoint.dart';

class DeleteToken extends Endpoint<String, void> {
  final DeleteTokenFromDatabase _deleteTokenFromDatabase;

  DeleteToken(this._deleteTokenFromDatabase);

  @override
  Future<void> request(String input) async {
    await _deleteTokenFromDatabase.request(input);
  }
}
