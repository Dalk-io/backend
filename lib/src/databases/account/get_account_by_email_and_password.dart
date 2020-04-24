import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/account/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetAccountByEmailAndPasswordFromDatabase extends DatabaseEndpoint<GetAccountByEmailAndPasswordParameters> {
  GetAccountByEmailAndPasswordFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT * FROM accounts WHERE email = @email AND password = @password',
            substitutionValues: <String, String>{
              'email': input.email,
              'password': input.password,
            },
          ),
        );
}
