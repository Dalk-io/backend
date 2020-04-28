import 'dart:io';

import 'package:shelf/shelf.dart';

final dalkCleanResponseMiddleware = createMiddleware(
  responseHandler: (response) => response.change(headers: {
    ...response.headers,
    HttpHeaders.serverHeader: null,
  }),
);
