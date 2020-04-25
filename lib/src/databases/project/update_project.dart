import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/project/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class UpdateProjectToDatabase extends DatabaseEndpoint<UpdateProjectParameters> {
  UpdateProjectToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'UPDATE projects SET productionWebHook = @productionWebHook, developmentWebHook = @developmentWebHook, secure = @isSecure WHERE id = @projectId',
            substitutionValues: <String, dynamic>{
              'projectId': input.projectId,
              'productionWebHook': input.productionWebHook,
              'developmentWebHook': input.developmentWebHook,
              'isSecure': input.isSecure,
            },
          ),
        );
}
