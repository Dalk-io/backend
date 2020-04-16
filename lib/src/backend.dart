import 'package:backend/src/api_v1/api.dart';
import 'package:backend/src/middlewares/cors.dart';
import 'package:backend/src/rpc/contact/save_contact.dart';
import 'package:backend/src/rpc/conversation/conversation.dart';
import 'package:backend/src/rpc/conversations/conversations.dart';
import 'package:backend/src/rpc/message/message.dart';
import 'package:backend/src/rpc/messages/messages.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'backend.g.dart';

@immutable
class Backend {
  final ConversationRpcs _conversationRpcs;
  final ConversationsRpcs _conversationsRpcs;
  final MessageRpcs _messageRpcs;
  final MessagesRpcs _messagesRpcs;
  final SaveContact _saveContact;

  final _logger = Logger('Backend');

  Backend(this._conversationRpcs, this._conversationsRpcs, this._messageRpcs, this._messagesRpcs, this._saveContact);

  Handler get handler => Pipeline()
      .addMiddleware(
          dalkCorsMiddleware({'Access-Control-Allow-Origin': '*', 'Access-Control-Request-Method': 'POST', 'Access-Control-Allow-Headers': 'Content-Type'}))
      .addHandler(_$BackendRouter(this).handler);

  @Route.mount('/v1/')
  Router get _api => ApiV1(_conversationRpcs, _conversationsRpcs, _messageRpcs, _messagesRpcs, _saveContact).router;

  @Route.all('/<ignored|.*>')
  Future<Response> fallback(Request request) async {
    final logger = Logger('${_logger.name}.fallback');
    logger.info('${request.method} ${request.requestedUri.path}');
    final body = await request.read().toList();
    logger.info('body: ${body.isNotEmpty ? body.first : <int>[]}');
    if (body.isNotEmpty) {
      logger.info(await request.change(body: body.isNotEmpty ? body.first : <int>[]).readAsString());
    }
    return Response.notFound('not found');
  }
}
