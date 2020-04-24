import 'package:backend/src/data/user/user.dart';
import 'package:backend/src/databases/user/save_user.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class SaveUser extends Endpoint<SaveUserParameters, UserData> {
  final SaveUserToDatabase _saveUserToDatabase;

  SaveUser(this._saveUserToDatabase);

  @override
  Future<UserData> request(SaveUserParameters input) async {
    final results = await _saveUserToDatabase.request(input);
    return UserData.fromDatabase(results.first);
  }
}
