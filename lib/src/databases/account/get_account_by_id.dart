import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetAccountByIdFromDatabase extends DatabaseEndpoint<int> {
  GetAccountByIdFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT * FROM accounts WHERE id = @id',
            substitutionValues: <String, int>{'id': input},
          ),
        );
}
