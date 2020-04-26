import 'dart:convert';
import 'dart:io';

import 'package:backend/src/api_v1/account/models/change_password/change_password.dart';
import 'package:backend/src/rpc/account/parameters.dart';
import 'package:backend/src/rpc/rpcs.dart';
import 'package:backend/src/utils/check_token.dart';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'account.g.dart';

class AccountService {
  final Rpcs _rpcs;

  AccountService(this._rpcs);

  Router get router => _$AccountServiceRouter(this);

  @Route('PATCH', '/change_password')
  Future<Response> changePassword(Request request) async {
    final tokenData = await getTokenData(request, _rpcs);
    if (tokenData == null) {
      return Response(HttpStatus.unauthorized);
    }
    final accountData = await _rpcs.accountRpcs.getAccountById.request(tokenData.accountId);
    final body = (json.decode(await request.readAsString()) as Map).cast<String, String>();
    final changePasswordDataRequest = ChangePasswordDataRequest.fromJson(body);
    final encryptedPassword = sha512.convert(utf8.encode(changePasswordDataRequest.password)).toString();
    await _rpcs.accountRpcs.updateAccount.request(UpdateAccountParameters(accountData.id, encryptedPassword));
    return Response(HttpStatus.notImplemented);
  }
}
