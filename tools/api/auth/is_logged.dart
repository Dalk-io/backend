import 'dart:convert';
import 'dart:io';

import 'package:backend/src/utils/pretty_json.dart';

import 'package:http/io_client.dart';

void main(List<String> arguments) async {
  final client = IOClient();
  final response = await client.get(
    'https://localhost:443/v1/auth/is_logged',
    headers: {
      HttpHeaders.authorizationHeader: arguments.first,
    },
  );
  print(response.statusCode);
  print(response.headers);
  prettyPrintJson(json.decode(response.body));
}
