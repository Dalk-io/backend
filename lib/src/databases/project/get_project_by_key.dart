import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetProjectByKeyFromDatabase extends DatabaseEndpoint<String> {
  GetProjectByKeyFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT name, productionKey, productionSecret, productionWebhook, developmentKey, developmentSecret, developmentWebhook, groupLimitation FROM projects WHERE productionKey == @key OR developmentKey == @key',
            substitutionValues: <String, dynamic>{
              'key': input,
            },
          ),
        );
}
