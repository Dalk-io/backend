import 'package:backend/src/databases/account/update_account.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/account/parameters.dart';

class UpdateAccount extends Endpoint<UpdateAccountParameters, void> {
  final UpdateAccountToDatabase _updateAccountToDatabase;

  UpdateAccount(this._updateAccountToDatabase);

  @override
  Future<void> request(UpdateAccountParameters input) async {
    await _updateAccountToDatabase.request(input);
  }
}
