import 'package:shelf/shelf.dart';

final dalkCorsMiddleware = (Map<String, String> corsHeaders) => createMiddleware(
      requestHandler: (request) {
        if (request.method == 'OPTIONS') {
          return Response.ok(null, headers: corsHeaders);
        } else {
          return null;
        }
      },
      responseHandler: (response) => response.change(headers: corsHeaders),
    );
