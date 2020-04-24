import 'package:backend/src/data/account/account.dart';
import 'package:backend/src/databases/account/get_account_by_email.dart';
import 'package:backend/src/endpoint.dart';

class GetAccountByEmail extends Endpoint<String, AccountData> {
  final GetAccountByEmailFromDatabase _getAccountByEmailFromDatabase;

  GetAccountByEmail(this._getAccountByEmailFromDatabase);

  @override
  Future<AccountData> request(String input) async {
    final results = await _getAccountByEmailFromDatabase.request(input);
    if (results.isEmpty) {
      return null;
    }
    return AccountData.fromDatabase(results.first);
  }
}
