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

  await pg.execute('DROP TABLE users;');
  await pg.execute('DROP TABLE conversations;');
  await pg.execute('DROP TABLE messages;');
  await pg.close();
}
