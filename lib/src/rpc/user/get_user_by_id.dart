import 'package:backend/src/data/user/user.dart';
import 'package:backend/src/databases/user/get_user_by_id.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetUserById extends Endpoint<GetUserByIdParameters, UserData> {
  final GetUserByIdFromDatabase _getUserByIdFromDatabase;

  GetUserById(this._getUserByIdFromDatabase);

  @override
  Future<UserData> request(GetUserByIdParameters input) async {
    final results = await _getUserByIdFromDatabase.request(input);
    if (results.isEmpty) {
      return null;
    }
    final result = results.first;
    return UserData(result[0] as String, name: result[1] as String, avatar: result[2] as String);
  }
}
