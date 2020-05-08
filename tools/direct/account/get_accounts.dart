//  ignore_for_file: avoid_print

import 'package:postgres_pool/postgres_pool.dart';

void main() async {
  final pg = PgPool(
    PgEndpoint(
      host: '51.159.24.51',
      port: 45107,
      database: 'development',
      username: 'dalk',
      password: 'Lg-)bTvEf=s2r}>yz2k@O',
      requireSsl: true,
    ),
    settings: PgPoolSettings()..concurrency = 10,
  );

  final results = await pg.query('SELECT * FROM accounts');

  for (final result in results) {
    print(result);
  }

  await pg.close();
}
