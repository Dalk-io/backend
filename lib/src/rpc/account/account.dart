import 'package:backend/src/rpc/account/get_account_by_email.dart';
import 'package:backend/src/rpc/account/save_account.dart';

class AccountRpcs {
  final SaveAccount saveAccount;
  final GetAccountByEmail getAccountByEmail;

  AccountRpcs(this.saveAccount, this.getAccountByEmail);
}
