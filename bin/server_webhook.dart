//  ignore_for_file: avoid_print

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() {
  shelf_io.serve(webhook, 'localhost', 8081);
}

Future<Response> webhook(Request request) async {
  final body = await request.readAsString();
  print(body);
  return Response.ok('');
}
