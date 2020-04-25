import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetConversationsForProjectFromDatabase extends DatabaseEndpoint<String> {
  GetConversationsForProjectFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT id, subject, avatar, admins, users, isGroup FROM conversations WHERE projectId = @projectId',
            substitutionValues: <String, dynamic>{
              'projectId': input,
            },
          ),
        );
}
