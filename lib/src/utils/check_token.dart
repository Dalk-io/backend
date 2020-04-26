import 'dart:io';

import 'package:backend/src/data/token/token.dart';
import 'package:backend/src/rpc/rpcs.dart';
import 'package:shelf/shelf.dart';

Future<TokenData> getTokenData(Request request, Rpcs rpcs) {
  final token = request.headers[HttpHeaders.authorizationHeader];
  if (token == null) {
    return null;
  }
  return rpcs.tokenRpcs.getToken.request(token);
}
