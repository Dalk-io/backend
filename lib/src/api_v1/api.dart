import 'dart:convert';
import 'dart:io';

import 'package:backend/src/api_v1/account/account.dart';
import 'package:backend/src/api_v1/auth/auth.dart';
import 'package:backend/src/api_v1/projects/project.dart';
import 'package:backend/src/rpc/contact/parameters.dart';
import 'package:backend/src/rpc/rpcs.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'api.g.dart';

@immutable
class ApiV1 {
  final Rpcs _rpcs;

  final _logger = Logger('ApiV1');

  ApiV1(this._rpcs);

  @Route.mount('/projects/')
  Router get _projectService => ProjectService(_rpcs).router;

  @Route.mount('/auth/')
  Router get _authService => AuthService(_rpcs.accountRpcs, _rpcs.projectRpcs, _rpcs.tokenRpcs).router;

  @Route.mount('/accounts/')
  Router get _accounts => AccountService(_rpcs).router;

  Router get router => _$ApiV1Router(this);

  @Route.post('/contact')
  Future<Response> contact(Request request) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.contact');
    final body = await request.readAsString();
    logger.finest('contact body $body');
    final parameters = SaveContactParameters.fromJson(json.decode(body) as Map<String, dynamic>);
    await _rpcs.contactRpcs.saveContact.request(parameters);
    logger.info('saving contact took ${sw.elapsed}');
    return Response(HttpStatus.created);
  }
}
