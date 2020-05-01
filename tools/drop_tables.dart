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

  await pg.execute('DROP TABLE accounts;');
  await pg.execute('DROP TABLE tokens;');
  await pg.execute('DROP TABLE users;');
  await pg.execute('DROP TABLE projects');
  await pg.execute('DROP TABLE conversations;');
  await pg.execute('DROP TABLE messages;');
  await pg.close();
}
