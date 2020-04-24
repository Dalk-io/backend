import 'dart:io';

import 'package:backend/src/rpc/rpcs.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'message.g.dart';

class MessageService {
  final Rpcs _rpcs;

  MessageService(this._rpcs);

  Router get router => _$MessageServiceRouter(this);

  @Route.get('/')
  Future<Response> getMessages(Request request) async {
    return Response(HttpStatus.notImplemented);
  }
}
