import 'dart:convert';
import 'dart:io';

import 'package:backend/backend.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('fallback', () async {
    final backend = Backend(null, null, null, null, null);
    final request = Request('GET', Uri.parse('http://localhost:8080/random_url'), body: utf8.encode('Hello world'));
    final response = await backend.fallback(request);
    expect(response.statusCode, HttpStatus.notFound);
    expect(await response.readAsString(), 'not found');
  });
}
