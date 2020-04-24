import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class UpdateUserByIdFromDatabase extends DatabaseEndpoint<UpdateUserParameters> {
  UpdateUserByIdFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'UPDATE users SET name = @name, avatar = @avatar, state = @state WHERE projectId = @projectId AND id = @id',
            substitutionValues: <String, dynamic>{
              'projectId': input.projectId,
              'id': input.id,
              'name': input.name,
              'avatar': input.avatar,
              'state': input.state.index,
            },
          ),
        );
}
