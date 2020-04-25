import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final response = await http.patch(
    'http://localhost:443/v1/projects/dev_70e9bfc0-86f8-11ea-8600-dba352199d7a/',
    headers: {
      HttpHeaders.authorizationHeader: arguments.first,
    },
    body: json.encode({'isSecure': true, 'webHook': null}),
  );
  print(response.statusCode);
  print(response.body);
}
