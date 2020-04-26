import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/account/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class UpdateAccountToDatabase extends DatabaseEndpoint<UpdateAccountParameters> {
  UpdateAccountToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'UPDATE accounts SET password = @password WHERE id = @id',
            substitutionValues: <String, dynamic>{
              'id': input.id,
              'password': input.password,
            },
          ),
        );
}
