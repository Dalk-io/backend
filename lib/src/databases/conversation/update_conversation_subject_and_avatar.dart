import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class UpdateConversationSubjectAndAvatarToDatabase extends DatabaseEndpoint<UpdateConversationSubjectAndAvatarParameters> {
  UpdateConversationSubjectAndAvatarToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'UPDATE conversations SET subject = @subject, avatar = @avatar WHERE projectId = @projectId AND id = @id',
            substitutionValues: <String, dynamic>{
              'projectId': input.projectId,
              'id': input.conversationId,
              'avatar': input.avatar,
              'subject': input.subject,
            },
          ),
        );
}
