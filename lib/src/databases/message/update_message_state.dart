import 'dart:convert';

import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class UpdateMessageStateToDatabase extends DatabaseEndpoint<UpdateMessageStateParameters> {
  UpdateMessageStateToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'UPDATE messages SET state = @state WHERE projectId = @projectId AND conversationId = @conversationId AND id = @id RETURNING projectId, id, conversationId, senderId, text, timestamp, state',
            substitutionValues: <String, dynamic>{
              'projectId': input.projectId,
              'conversationId': input.conversationId,
              'id': input.messageId,
              'state': json.encode(input.states.map((stateByUser) => {'id': stateByUser.id, 'state': stateByUser.state.index}).toList()),
            },
          ),
        );
}
