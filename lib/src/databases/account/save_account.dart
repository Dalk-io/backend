import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/account/parameters.dart';
import 'package:meta/meta.dart';
import 'package:postgres_pool/postgres_pool.dart';

@immutable
class SaveAccountToDatabase extends DatabaseEndpoint<SaveAccountParameters> {
  SaveAccountToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'INSERT INTO accounts (firstName, lastName, email, password, projectId) VALUES (@firstName, @lastName, @email, @password, @projectId) RETURNING id;',
            substitutionValues: <String, dynamic>{
              'firstName': input.firstName,
              'lastName': input.lastName,
              'email': input.email,
              'password': input.password,
              'projectId': input.projectId,
            },
          ),
        );
}
