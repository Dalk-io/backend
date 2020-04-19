import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/conversations/parameters.dart';
import 'package:meta/meta.dart';
import 'package:postgres_pool/postgres_pool.dart';

@immutable
class GetConversationsForUserFromDatabase extends DatabaseEndpoint<GetConversationsForUserParameters> {
  GetConversationsForUserFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT id, subject, avatar, admins, users, isGroup FROM conversations WHERE projectId = @projectId AND (users)::jsonb ? @userId ORDER BY lastUpdate DESC',
            substitutionValues: <String, String>{
              'projectId': input.projectId,
              'userId': input.userId,
            },
          ),
        );
}
