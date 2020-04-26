import 'dart:convert';
import 'dart:io';

import 'package:backend/src/utils/pretty_print_json.dart';
import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final response = await http.get(
    'http://localhost:443/v1/auth/is_logged',
    headers: {
      HttpHeaders.authorizationHeader: arguments.first,
    },
  );
  print(response.statusCode);
  prettyPrintJson(json.decode(response.body));
}
