import 'package:backend/src/data/token/token.dart';
import 'package:backend/src/databases/token/get_token.dart';
import 'package:backend/src/endpoint.dart';

class GetToken extends Endpoint<String, TokenData> {
  final GetTokenFromDatabase _getTokenFromDatabase;

  GetToken(this._getTokenFromDatabase);

  @override
  Future<TokenData> request(String input) async {
    final results = await _getTokenFromDatabase.request(input);
    if (results.isEmpty || results.length > 1) {
      return null;
    }
    return TokenData.fromDatabase(results.first);
  }
}
