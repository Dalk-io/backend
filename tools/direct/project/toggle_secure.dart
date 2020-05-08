//  ignore_for_file: avoid_print

import 'dart:io';

import 'package:postgres_pool/postgres_pool.dart';

void main(List<String> arguments) async {
  if (arguments.length != 2) {
    print('this script take only two parameters which is the project key and 0/1');
    exit(1);
  }
  final pg = PgPool(
    PgEndpoint(
      host: '51.159.26.58',
      port: 10480,
      database: 'rdb',
      username: 'dalk',
      password: 'MmA1@<s|cV#"\'0BX}[zJ4',
      requireSsl: true,
    ),
    settings: PgPoolSettings()..concurrency = 10,
  );

  await pg.query(
    '''UPDATE projects SET secure = @secure WHERE productionKey = @key OR developmentKey = @key''',
    substitutionValues: <String, dynamic>{
      'key': arguments.first,
      'secure': arguments.last == '0' ? false : true,
    },
  );

  await pg.close();
}
