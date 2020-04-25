import 'dart:convert';
import 'dart:io';

import 'package:backend/src/utils/pretty_print_json.dart';
import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final response = await http.get(
    'http://localhost:443/v1/projects/dev_70e9bfc0-86f8-11ea-8600-dba352199d7a/conversations',
    headers: {
      HttpHeaders.authorizationHeader: arguments.first,
    },
  );
  if (response.statusCode != 200) {
    print(response.statusCode);
    return;
  }
  prettyPrintJson(json.decode(response.body) as List);
}
