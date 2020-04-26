import 'package:backend/src/api_v1/api.dart';
import 'package:backend/src/middlewares/cors.dart';
import 'package:backend/src/rpc/rpcs.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'backend.g.dart';

@immutable
class Backend {
  final Rpcs _rpcs;

  final _logger = Logger('Backend');

  Backend(this._rpcs);

  Handler get handler => Pipeline()
      .addMiddleware(dalkCorsMiddleware({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Request-Method': 'GET, POST, PATCH, PUT, DELETE',
        'Access-Control-Allow-Headers': 'Content-Type'
      }))
      .addHandler(_$BackendRouter(this).handler);

  @Route.mount('/v1/')
  Router get _api => ApiV1(_rpcs).router;

  @Route.get('/ping')
  Response ping(Request request) => Response.ok('pong');

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
