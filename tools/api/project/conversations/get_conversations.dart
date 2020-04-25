import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final response = await http.get(
    'http://localhost:443/v1/projects/dev_cb76ca50-8635-11ea-e3cb-ebee2a9893a6/conversations',
    headers: {
      HttpHeaders.authorizationHeader: arguments.first,
    },
  );
  print(response.statusCode);
  print(response.body);
  final encoder = JsonEncoder.withIndent('  ');
  final prettyprint = encoder.convert(json.decode(response.body));
  print(prettyprint);
}
