import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final response = await http.patch(
    'https://staging.api.dalk.io/v1/projects/dev_5a7485b0-870a-11ea-ccaa-79b555c1a36f',
    headers: {
      HttpHeaders.authorizationHeader: arguments.first,
    },
    body: json.encode({'isSecure': false}),
  );
  print(response.statusCode);
  print(response.body);
  print(response.headers);
}
