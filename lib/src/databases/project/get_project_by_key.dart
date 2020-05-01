import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetProjectByKeyFromDatabase extends DatabaseEndpoint<String> {
  GetProjectByKeyFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT id, productionKey, productionSecret, productionWebHook, productionSecure, developmentKey, developmentSecret, developmentWebHook, developmentSecure, subscriptionType FROM projects WHERE productionKey = @key OR developmentKey = @key',
            substitutionValues: <String, dynamic>{
              'key': input,
            },
          ),
        );
}
