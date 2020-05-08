//  ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;

void main() async {
  final response = await http.post('http://localhost:443/v1/auth/login',
      body: json.encode(
        {
          'email': 'dev@dalk.io',
          'password': 'tata-fr-dalk',
        },
      ));
  print(response.statusCode);
  print(response.body);
}
