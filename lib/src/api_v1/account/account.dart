import 'dart:io';

import 'package:backend/src/rpc/rpcs.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'account.g.dart';

class AccountService {
  final Rpcs _rpcs;

  AccountService(this._rpcs);

  Router get router => _$AccountServiceRouter(this);

  @Route.post('/change_password')
  Future<Response> changePassword(Request request) async {
    return Response(HttpStatus.notImplemented);
  }
}
