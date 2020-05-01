import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:meta/meta.dart';
import 'package:postgres_pool/postgres_pool.dart';

@immutable
class GetLastMessageForConversationFromDatabase extends DatabaseEndpoint<GetLastMessageForConversationParameters> {
  GetLastMessageForConversationFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT id, projectId, conversationId, senderId, text, createdAt, statusDetails, metadata, modifiedAt FROM messages WHERE projectId = @projectId AND conversationId = @conversationId ORDER BY createdAt DESC LIMIT 1;',
            substitutionValues: <String, String>{
              'projectId': input.projectId,
              'conversationId': input.conversationId,
            },
          ),
        );
}
