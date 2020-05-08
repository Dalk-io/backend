//  ignore_for_file: avoid_print

import 'dart:io';

import 'package:backend/backend.dart';

void main(List<String> arguments) async {
  if (arguments.length != 2) {
    print('this script take only two parameters which is the project key and 0/1');
    exit(1);
  }
  final pg = getPgPool('production');

  await pg.query(
    '''UPDATE projects SET secure = @secure WHERE productionKey = @key OR developmentKey = @key''',
    substitutionValues: <String, dynamic>{
      'key': arguments.first,
      'secure': arguments.last == '0' ? false : true,
    },
  );

  await pg.close();
}
