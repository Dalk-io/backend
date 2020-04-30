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

  await pg.execute('ALTER TABLE messages ADD COLUMN metadata json;');
  await pg.execute('ALTER TABLE messages ADD COLUMN modifiedAt TIMESTAMPTZ;');
  await pg.execute('ALTER TABLE messages RENAME COLUMN timestamp TO createdAt;');

  await pg.close();
}
