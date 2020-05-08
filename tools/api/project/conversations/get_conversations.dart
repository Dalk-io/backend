//  ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:backend/src/utils/pretty_json.dart';
import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final response = await http.get(
    'http://localhost:443/v1/projects/dev_5a7485b0-870a-11ea-ccaa-79b555c1a36f/conversations',
    headers: {
      HttpHeaders.authorizationHeader: arguments.first,
    },
  );
  print(response.statusCode);
  if (response.statusCode != 200) {
    print(response.statusCode);
    return;
  }
  prettyPrintJson(json.decode(response.body));
}
