import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetNumberOfMessageForConversationFromDatabase extends DatabaseEndpoint<GetNumberOfMessageForConversationParameter> {
  GetNumberOfMessageForConversationFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT COUNT(*) FROM messages WHERE projectId = @projectId AND conversationId = @conversationId',
            substitutionValues: <String, dynamic>{'projectId': input.projectId, 'converstionId': input.conversationId},
          ),
        );
}
