import 'package:backend/src/databases/user/update_user.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class UpdateUserById extends Endpoint<UpdateUserParameters, void> {
  final UpdateUserByIdFromDatabase _updateUserByIdFromDatabase;

  UpdateUserById(this._updateUserByIdFromDatabase);

  @override
  Future<void> request(UpdateUserParameters input) async {
    await _updateUserByIdFromDatabase.request(input);
  }
}
