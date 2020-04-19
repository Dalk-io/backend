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

  await pg.execute('CREATE TABLE IF NOT EXISTS contacts (fullName TEXT NOT NULL, email TEXT NOT NULL, phone TEXT NOT NULL, plan TEXT NOT NULL);');
  await pg.execute('CREATE TABLE IF NOT EXISTS users (projectId TEXT NOT NULL, id TEXT NOT NULL);');
  await pg.execute(
      'CREATE TABLE IF NOT EXISTS conversations (projectId TEXT NOT NULL, id TEXT NOT NULL, subject TEXT, avatar TEXT, admins json NOT NULL, users json NOT NULL, lastUpdate TIMESTAMPTZ NOT NULL, isGroup boolean NOT NULL);');
  await pg.execute(
      'CREATE TABLE IF NOT EXISTS messages (projectId TEXT NOT NULL, id serial PRIMARY KEY, conversationId TEXT NOT NULL, senderId TEXT NOT NULL, text TEXT, timestamp TIMESTAMPTZ NOT NULL, state json NOT NULL);');
  await pg.close();
}
