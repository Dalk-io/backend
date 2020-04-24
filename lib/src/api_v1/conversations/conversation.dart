import 'dart:io';

import 'package:backend/src/api_v1/conversations/messages/message.dart';
import 'package:backend/src/rpc/rpcs.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'conversation.g.dart';

class ConversationService {
  final Rpcs _rpcs;

  ConversationService(this._rpcs);

  Router get router => _$ConversationServiceRouter(this);

  @Route.mount('/messages/')
  Router get _messages => MessageService(_rpcs).router;

  @Route.get('/')
  Future<Response> getConversations(Request request) async {
    final token = request.headers[HttpHeaders.authorizationHeader];
    if (token == null) {
      return Response(HttpStatus.unauthorized);
    }
    final tokenData = await _rpcs.tokenRpcs.getToken.request(token);
    if (tokenData == null) {
      return Response(HttpStatus.unauthorized);
    }
    final accountData = await _rpcs.accountRpcs.getAccountById.request(tokenData.accountId);
    // final conversationsData = await _rpcs.conversationsRpcs.getConversationsForUser

    return Response(HttpStatus.notImplemented);
  }

  @Route.get('/<conversationId>')
  Future<Response> getConversationById(Request request) async {
    return Response(HttpStatus.notImplemented);
  }
}
