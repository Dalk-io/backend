import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

Response checkRequestParameters(List<String> parameters, Map<String, dynamic> body) {
  final missingParameters = body.keys.map((key) => !body.keys.contains(key) ? key : null).where((key) => key != null);
  if (missingParameters.isNotEmpty) {
    return Response(
      HttpStatus.badRequest,
      body: json.encode({
        'message': 'Missing required parameters',
        'data': missingParameters,
      }),
    );
  }
  return null;
}
