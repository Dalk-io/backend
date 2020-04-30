import 'dart:convert';
import 'dart:io';

import 'package:backend/src/utils/pretty_json.dart';

import 'package:http/io_client.dart';

void main(List<String> arguments) async {
  // final sw = Stopwatch()..start();
  final httpClient = HttpClient();
  final client = IOClient(httpClient);
  // final requests = List.generate(
  //   10000,
  //   (_) => client.get(
  //     'https://api.dalk.io/v1/auth/is_logged',
  //     headers: {
  //       HttpHeaders.authorizationHeader: arguments.first,
  //     },
  //   ),
  // );

  // print('waiting request to complete');
  // final results = await Future.wait(requests);
  // print('end in ${sw.elapsed}');

  // print(results.where((result) => result.statusCode != 200).length);
  // if (results.where((result) => result.statusCode != 200).isNotEmpty) {
  //   print(results.where((result) => result.statusCode != 200).first.body);
  // }
  // results.where((result) => result.statusCode == 200).forEach((result) => prettyPrintJson(json.decode(result.body)));

  try {
    final response = await client.get(
      'https://staging.api.dalk.io/v1/auth/is_logged',
      headers: {
        HttpHeaders.authorizationHeader: arguments.first,
      },
    );
    print(response.statusCode);
    print(response.headers);
    prettyPrintJson(json.decode(response.body));
  } catch (e) {
    print(e);
  }
}
