import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final response = await http.post(
    'http://localhost:443/v1/projects/dev_cb76ca50-8635-11ea-e3cb-ebee2a9893a6',
    headers: {
      HttpHeaders.authorizationHeader: arguments.first,
    },
    body: json.encode({'isSecure': true}),
  );
  print(response.statusCode);
  print(response.body);
}
