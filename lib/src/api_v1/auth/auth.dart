import 'dart:io';

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'auth.g.dart';

@immutable
class AuthService {
  Router get router => _$AuthServiceRouter(this);

  @Route.post('/login')
  Future<Response> login(Request request) async {
    return Response(HttpStatus.notImplemented, body: 'not implemented');
  }

  @Route.post('/logout')
  Future<Response> logout(Request request) async {
    return Response(HttpStatus.notImplemented, body: 'not implemented');
  }

  @Route.post('/register')
  Future<Response> register(Request request) async {
    return Response(HttpStatus.notImplemented, body: 'not implemented');
  }
}
