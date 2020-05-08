//  ignore_for_file: avoid_print

import 'package:postgres_pool/postgres_pool.dart';

void main() async {
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

  final results = await pg.query('SELECT * FROM users WHERE projectId = \'dev_094b5c50-8344-11ea-c31d-39a75c9c99e5\'');
  print(results);

  await pg.close();
}
