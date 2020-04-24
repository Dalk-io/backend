import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class DeleteTokenFromDatabase extends DatabaseEndpoint<String> {
  DeleteTokenFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'DELETE FROM tokens WHERE token = @token',
            substitutionValues: <String, String>{'token': input},
          ),
        );
}
