import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:meta/meta.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:postgres_pool/postgres_pool.dart';

@immutable
class GetConversationByIdFromDatabase extends DatabaseEndpoint<GetConversationByIdParameters> {
  GetConversationByIdFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT id, subject, avatar, admins, users FROM conversations WHERE projectId = @projectId AND id = @id',
            substitutionValues: <String, String>{
              'projectId': input.projectId,
              'id': input.conversationId,
            },
          ),
        );
}
