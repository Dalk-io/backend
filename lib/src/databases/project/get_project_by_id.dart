import 'package:backend/src/databases/database_endpoint.dart';
import 'package:postgres_pool/postgres_pool.dart';

class GetProjectByIdFromDatabase extends DatabaseEndpoint<int> {
  GetProjectByIdFromDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'SELECT productionKey, productionSecret, productionWebHook, developmentKey, developmentSecret, developmentWebHook, plan, groupLimitation, secure FROM projects WHERE id = @id',
            substitutionValues: <String, int>{
              'id': input,
            },
          ),
        );
}
