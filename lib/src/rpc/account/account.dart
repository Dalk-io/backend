import 'package:backend/src/rpc/account/get_account_by_email.dart';
import 'package:backend/src/rpc/account/get_account_by_email_and_password.dart';
import 'package:backend/src/rpc/account/get_account_by_id.dart';
import 'package:backend/src/rpc/account/save_account.dart';

class AccountRpcs {
  final SaveAccount saveAccount;
  final GetAccountByEmail getAccountByEmail;
  final GetAccountByEmailAndPassword getAccountByEmailAndPassword;
  final GetAccountById getAccountById;

  AccountRpcs(
    this.saveAccount,
    this.getAccountByEmail,
    this.getAccountByEmailAndPassword,
    this.getAccountById,
  );
}
