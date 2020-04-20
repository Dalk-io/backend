import 'package:backend/src/databases/account/get_account_by_email.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/models/account.dart';

class GetAccountByEmail extends Endpoint<String, Account> {
  final GetAccountByEmailFromDatabase _getAccountByEmailFromDatabase;

  GetAccountByEmail(this._getAccountByEmailFromDatabase);

  @override
  Future<Account> request(String input) async {
    final results = await _getAccountByEmailFromDatabase.request(input);
    if (results.isEmpty) {
      return null;
    }
    print(results);
    return Account.fromDatabase(results.first);
  }
}
