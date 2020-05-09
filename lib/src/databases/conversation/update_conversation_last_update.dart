import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class UpdateConversationLastUpdateToDatabase extends DatabaseEndpoint<UpdateConversationLastUpdateParameters> {
  UpdateConversationLastUpdateToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'UPDATE conversations SET lastMessageCreatedAt = @lastMessageCreatedAt WHERE projectId = @projectId AND id = @conversationId',
            substitutionValues: <String, dynamic>{
              'lastMessageCreatedAt': DateTime.now().toUtc().toIso8601String(),
              'projectId': input.projectId,
              'conversationId': input.conversationId,
            },
          ),
        );
}
