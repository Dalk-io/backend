import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class SaveProjectToDatabase extends DatabaseEndpoint<ProjectsData> {
  SaveProjectToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'INSERT INTO projects (productionKey, productionSecret, productionWebHook, productionSecure, developmentKey, developmentSecret, developmentWebHook, developmentSecure, subscriptionType) VALUES (@productionKey, @productionSecret, @productionWebHook, @productionSecure, @developmentKey, @developmentSecret, @developmentWebHook, @developmentSecure, @subscriptionType) RETURNING id;',
            substitutionValues: <String, dynamic>{
              'productionKey': input.production?.key,
              'productionSecret': input.production?.secret,
              'productionWebHook': input.production?.webHook,
              'productionSecure': input.production?.isSecure,
              'developmentKey': input.development.key,
              'developmentSecret': input.development.secret,
              'developmentWebHook': input.development.webHook,
              'developmentSecure': input.development.isSecure,
              'subscriptionType': input.subscriptionType.index,
            },
          ),
        );
}
