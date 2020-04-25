import 'dart:convert';

import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class UpdateMessageStatusToDatabase extends DatabaseEndpoint<UpdateMessageStatusParameters> {
  UpdateMessageStatusToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'UPDATE messages SET statusDetails = @statusDetails WHERE projectId = @projectId AND conversationId = @conversationId AND id = @id RETURNING id, projectId, conversationId, senderId, text, timestamp, statusDetails',
            substitutionValues: <String, dynamic>{
              'projectId': input.projectId,
              'conversationId': input.conversationId,
              'id': input.messageId,
              'statusDetails': json.encode(input.statusDetails.map((statusByUser) => {'id': statusByUser.id, 'status': statusByUser.status.index}).toList()),
            },
          ),
        );
}
