import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetTokenFromDatabase extends DatabaseEndpoint<String> {
  GetTokenFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT token, accountId, id, createdAt FROM tokens WHERE token = @token',
            substitutionValues: <String, String>{
              'token': input,
            },
          ),
        );
}
