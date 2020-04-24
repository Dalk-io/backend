import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class SaveUserToDatabase extends DatabaseEndpoint<SaveUserParameters> {
  SaveUserToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'INSERT INTO users (projectId, id, name, avatar, state) VALUES (@projectId, @id, @name, @avatar, @state) RETURNING id, name, avatar, state;',
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
