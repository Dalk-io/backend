import 'dart:convert';

import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class SaveMessageToDatabase extends DatabaseEndpoint<SaveMessageParameters> {
  SaveMessageToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'INSERT INTO messages (id, projectId, conversationId, senderId, text, timestamp, state) VALUES (@id, @projectId, @conversationId, @senderId, @text, @timestamp, @state);',
            substitutionValues: <String, dynamic>{
              'id': input.id,
              'projectId': input.projectId,
              'conversationId': input.conversationId,
              'senderId': input.senderId,
              'text': input.text,
              'timestamp': DateTime.now().toUtc(),
              'state': json.encode(input.states.map((stateByUser) => {'id': stateByUser.id, 'state': stateByUser.state.index}).toList()),
            },
          ),
        );
}
