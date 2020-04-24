import 'package:backend/src/data/account/account.dart';
import 'package:backend/src/databases/account/get_account_by_id.dart';
import 'package:backend/src/endpoint.dart';

class GetAccountById extends Endpoint<int, AccountData> {
  final GetAccountByIdFromDatabase _getAccountByIdFromDatabase;

  GetAccountById(this._getAccountByIdFromDatabase);

  @override
  Future<AccountData> request(int input) async {
    final results = await _getAccountByIdFromDatabase.request(input);
    if (results.isEmpty) {
      return null;
    }
    return AccountData.fromDatabase(results.first);
  }
}
