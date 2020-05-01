import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetMessageByIdFromDatabase extends DatabaseEndpoint<GetMessageByIdParameters> {
  GetMessageByIdFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT id, projectId, conversationId, senderId, text, createdAt, statusDetails, metadata, modifiedAt FROM messages WHERE projectId = @projectId AND id = @messageId',
            substitutionValues: <String, dynamic>{
              'messageId': input.messageId,
              'projectId': input.projectId,
            },
          ),
        );
}
