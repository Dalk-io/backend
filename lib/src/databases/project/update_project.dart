import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class UpdateProjectToDatabase extends DatabaseEndpoint<ProjectsData> {
  UpdateProjectToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'UPDATE projects SET productionKey = @productionKey, productionSecret = @productionSecret, productionWebHook = @productionWebHook, developmentWebHook = @developmentWebHook, productionSecure = @productionSecure, developmentSecure = @developmentSecure, subscriptionType = @subscriptionType WHERE id = @projectId',
            substitutionValues: <String, dynamic>{
              'projectId': input.id,
              'productionKey': input.production?.key,
              'productionSecret': input.production?.secret,
              'productionWebHook': input.production?.webHook,
              'developmentWebHook': input.development?.webHook,
              'productionSecure': input.production.isSecure,
              'developmentSecure': input.development.isSecure,
              'subscriptionType': input.subscriptionType.index,
            },
          ),
        );
}
