import 'package:backend/src/databases/account/save_account.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/account/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class SaveAccount extends Endpoint<SaveAccountParameters, int> {
  final SaveAccountToDatabase _saveAccountToDatabase;

  SaveAccount(this._saveAccountToDatabase);

  @override
  Future<int> request(SaveAccountParameters input) async {
    final results = await _saveAccountToDatabase.request(input);
    return results.first.first as int;
  }
}
