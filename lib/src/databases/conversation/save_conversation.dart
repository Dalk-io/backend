import 'dart:convert';

import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:meta/meta.dart';
import 'package:postgres_pool/postgres_pool.dart';

@immutable
class SaveConversationToDatabase extends DatabaseEndpoint<SaveConversationParameters> {
  SaveConversationToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'INSERT INTO conversations (projectId, id, subject, avatar, admins, users, lastUpdate) VALUES (@projectId, @id, @subject, @avatar, @admins, @users, @lastUpdate);',
            substitutionValues: <String, dynamic>{
              'projectId': input.projectId,
              'id': input.conversation.id,
              'subject': input.conversation.subject,
              'avatar': input.conversation.avatar,
              'admins': json.encode(input.conversation.admins.toList()),
              'users': json.encode(input.conversation.users.toList()),
              'lastUpdate': DateTime.now().toUtc(),
            },
          ),
        );
}
