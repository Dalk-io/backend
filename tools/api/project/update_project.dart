//  ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final response = await http.patch(
    'http://localhost:443/v1/projects/dev_5a7485b0-870a-11ea-ccaa-79b555c1a36f',
    headers: {
      HttpHeaders.authorizationHeader: arguments.first,
    },
    body: json.encode({'isSecure': true}),
  );
  print(response.statusCode);
  print(response.body);
  print(response.headers);
}
