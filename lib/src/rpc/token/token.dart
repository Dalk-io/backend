import 'package:backend/src/rpc/token/delete_token.dart';
import 'package:backend/src/rpc/token/get_token.dart';
import 'package:backend/src/rpc/token/save_token.dart';

class TokenRpcs {
  final SaveToken saveToken;
  final GetToken getToken;
  final DeleteToken deleteToken;

  TokenRpcs(this.saveToken, this.getToken, this.deleteToken);
}
