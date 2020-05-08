import 'dart:io';

import 'package:postgres_pool/postgres_pool.dart';

PgPool getPgPool(String database, {PgPoolSettings settings}) => PgPool(
      PgEndpoint(
        host: Platform.environment['DATABASE_HOST'],
        port: int.parse(Platform.environment['DATABASE_PORT']),
        database: database,
        username: Platform.environment['DATABASE_USERNAME'],
        password: Platform.environment['DATABASE_PASSWORD'],
        requireSsl: true,
      ),
      settings: settings ?? PgPoolSettings()
        ..concurrency = 10,
    );
