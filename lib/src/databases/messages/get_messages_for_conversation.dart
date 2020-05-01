import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/messages/parameters.dart';
import 'package:meta/meta.dart';
import 'package:postgres_pool/postgres_pool.dart';

@immutable
class GetMessagesForConversationFromDatabase extends DatabaseEndpoint<GetMessagesForConversationParameters> {
  GetMessagesForConversationFromDatabase(PgPool pgPool)
      : super(
            pgPool,
            (input) => pgPool.query(
                  'SELECT id, projectId, conversationId, senderId, text, createdAt, statusDetails FROM messages WHERE projectId = @projectId AND conversationId = @conversationId ORDER BY createdAt ASC',
                  substitutionValues: <String, String>{
                    'projectId': input.projectId,
                    'conversationId': input.conversationId,
                  },
                ));
}
