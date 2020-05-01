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

  await pg.execute('CREATE TABLE IF NOT EXISTS contacts (fullName TEXT NOT NULL, email TEXT NOT NULL, phone TEXT NOT NULL, plan TEXT NOT NULL);');

  await pg.execute(
      'CREATE TABLE IF NOT EXISTS accounts (id serial PRIMARY KEY, firstName TEXT NOT NULL, lastName TEXT NOT NULL, email TEXT NOT NULL, password TEXT NOT NULL, projectId INTEGER NOT NULL);');
  await pg
      .execute('CREATE TABLE IF NOT EXISTS tokens (id serial PRIMARY KEY, accountId INTEGER NOT NULL, token TEXT NOT NULL, createdAt TIMESTAMPTZ NOT NULL);');

  await pg.execute('''CREATE TABLE IF NOT EXISTS projects (
  id serial PRIMARY KEY, 
  productionKey TEXT, 
  productionSecret TEXT, 
  productionWebHook TEXT, 
  productionSecure boolean,
  developmentKey TEXT NOT NULL,
  developmentSecret TEXT NOt NULL,
  developmentWebHook TEXT,
  developmentSecure boolean NOT NULL,
  subscriptionType INTEGER
)''');
  await pg.execute('CREATE TABLE IF NOT EXISTS users (projectId TEXT NOT NULL, id TEXT NOT NULL, name TEXT, avatar TEXT, state INTEGER);');
  await pg.execute(
      'CREATE TABLE IF NOT EXISTS conversations (projectId TEXT NOT NULL, id TEXT NOT NULL, subject TEXT, avatar TEXT, admins json NOT NULL, users json NOT NULL, lastUpdate TIMESTAMPTZ NOT NULL, isGroup boolean NOT NULL);');
  await pg.execute(
      'CREATE TABLE IF NOT EXISTS messages (projectId TEXT NOT NULL, id TEXT PRIMARY KEY, conversationId TEXT NOT NULL, senderId TEXT NOT NULL, text TEXT, createdAt TIMESTAMPTZ NOT NULL, statusDetails json NOT NULL, modifiedAt TIMESTAMPTZ, metadata json);');
  await pg.close();
}
