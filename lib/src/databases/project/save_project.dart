import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/models/project.dart';
import 'package:postgres_pool/postgres_pool.dart';

class SaveProjectToDatabase extends DatabaseEndpoint<Project> {
  SaveProjectToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'INSERT INTO projects (productionKey, productionSecret, productionWebhook, developmentKey, developmentSecret, developmentWebhook, groupLimitation, secure) VALUES (@productionKey, @productionSecret, @productionWebhook, @developmentKey, @developmentSecret, @developmentWebhook, @groupLimitation, @secure) RETURNING id;',
            substitutionValues: <String, dynamic>{
              'productionKey': input.production?.key,
              'productionSecret': input.production?.secret,
              'productionWebhook': input.production?.webhook,
              'developmentKey': input.development.key,
              'developmentSecret': input.development.secret,
              'developmentWebhook': input.development.webhook,
              'groupLimitation': input.development.groupLimitation,
              'secure': input.development.secure,
            },
          ),
        );
}
