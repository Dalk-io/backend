import 'dart:convert';

import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class UpdateMessageToDatabase extends DatabaseEndpoint<MessageData> {
  UpdateMessageToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'UPDATE messages SET statusDetails = @statusDetails, metadata = @metadata, modifiedAt = @modifiedAt, text = @text WHERE projectId = @projectId AND conversationId = @conversationId AND id = @id RETURNING id, projectId, conversationId, senderId, text, createdAt, statusDetails, metadata, modifiedAt',
            substitutionValues: <String, dynamic>{
              'projectId': input.projectId,
              'conversationId': input.conversationId,
              'id': input.id,
              'text': input.text,
              'statusDetails': json.encode(input.statusDetails.map((statusByUser) => {'id': statusByUser.id, 'status': statusByUser.status.index}).toList()),
              'metadata': input.metadata != null ? json.encode(input.metadata) : null,
              'modifiedAt': DateTime.now().toUtc(),
            },
          ),
        );
}
