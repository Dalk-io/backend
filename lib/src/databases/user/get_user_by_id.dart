import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetUserByIdFromDatabase extends DatabaseEndpoint<GetUserByIdParameters> {
  GetUserByIdFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT id, name, avatar FROM users WHERE projectId = @projectId AND id = @id',
            substitutionValues: <String, String>{
              'projectId': input.projectId,
              'id': input.id,
            },
          ),
        );
}
