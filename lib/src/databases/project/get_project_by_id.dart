import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetProjectByIdFromDatabase extends DatabaseEndpoint<int> {
  GetProjectByIdFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT id, productionKey, productionSecret, productionWebHook, productionSecure, developmentKey, developmentSecret, developmentWebHook, developmentSecure, subscriptionType FROM projects WHERE id = @id',
            substitutionValues: <String, int>{
              'id': input,
            },
          ),
        );
}
