import 'dart:convert';

String prettyJson(dynamic data) {
  final encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(data);
}

void prettyPrintJson(dynamic data) {
  print(prettyJson(data));
}
