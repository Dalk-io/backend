import 'package:backend/src/data/account/account.dart';
import 'package:backend/src/databases/account/get_account_by_email_and_password.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/account/parameters.dart';

class GetAccountByEmailAndPassword extends Endpoint<GetAccountByEmailAndPasswordParameters, AccountData> {
  final GetAccountByEmailAndPasswordFromDatabase _getAccountByEmailAndPasswordFromDatabase;

  GetAccountByEmailAndPassword(this._getAccountByEmailAndPasswordFromDatabase);

  @override
  Future<AccountData> request(GetAccountByEmailAndPasswordParameters input) async {
    final results = await _getAccountByEmailAndPasswordFromDatabase.request(input);
    if (results.isEmpty) {
      return null;
    }
    return AccountData.fromDatabase(results.first);
  }
}
