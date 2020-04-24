import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/token/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class SaveTokenToDatabase extends DatabaseEndpoint<SaveTokenParameters> {
  SaveTokenToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'INSERT INTO tokens (accountId, token, createdAt) VALUES (@accountId, @token, @created)',
            substitutionValues: <String, dynamic>{
              'accountId': input.accountId,
              'token': input.token,
              'created': input.createdAt,
            },
          ),
        );
}
