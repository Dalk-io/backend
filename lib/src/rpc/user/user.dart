import 'package:backend/src/rpc/user/get_user_by_id.dart';
import 'package:backend/src/rpc/user/save_user.dart';
import 'package:backend/src/rpc/user/update_user.dart';

class UserRpcs {
  final SaveUser saveUser;
  final GetUserById getUserById;
  final UpdateUserById updateUserById;

  UserRpcs(this.saveUser, this.getUserById, this.updateUserById);
}
