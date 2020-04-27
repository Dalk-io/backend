import 'dart:async';

import 'package:backend/src/endpoint.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres_pool/postgres_pool.dart';
import 'package:retry/retry.dart';

class DatabaseEndpoint<Input> extends Endpoint<Input, List<List>> {
  @protected
  final PgPool pgPool;
  final Future<PostgreSQLResult> Function(Input input) query;

  DatabaseEndpoint(this.pgPool, this.query);

  @override
  Future<List<List>> request(Input input) async {
    final results = await retry(() => query(input));
    return <List<dynamic>>[
      for (final result in results) result.toList(),
    ];
  }
}
