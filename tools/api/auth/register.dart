import 'dart:convert';

import 'package:http/http.dart' as http;

void main() async {
  final response = await http.post('http://localhost:443/v1/auth/register',
      body: json.encode(
        {
          'firstName': 'Dalk',
          'lastName': 'Dalk',
          'email': 'dev@dalk.io',
          'password': 'tata-fr-dalk',
          'subscriptionType': 'starter',
        },
      ));
  print(response.body);
}
