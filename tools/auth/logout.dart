import 'dart:io';

import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final response = await http.post('http://localhost:443/v1/auth/logout', headers: {
    HttpHeaders.authorizationHeader: arguments.first,
  });
  print(response.statusCode);
}
