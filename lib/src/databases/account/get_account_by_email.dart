import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetAccountByEmailFromDatabase extends DatabaseEndpoint<String> {
  GetAccountByEmailFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT * FROM accounts WHERE email = @email',
            substitutionValues: <String, String>{'email': input},
          ),
        );
}
