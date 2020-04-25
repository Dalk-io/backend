import 'dart:convert';

void prettyPrintJson(dynamic data) {
  final encoder = JsonEncoder.withIndent('  ');
  final prettyprint = encoder.convert(data);
  print(prettyprint);
}
