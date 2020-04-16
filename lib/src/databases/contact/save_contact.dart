import 'package:backend/src/databases/database_endpoint.dart';
import 'package:backend/src/rpc/contact/parameters.dart';
import 'package:postgres_pool/postgres_pool.dart';

class SaveContactToDatabase extends DatabaseEndpoint<SaveContactParameters> {
  SaveContactToDatabase(PgPool pgPool)
      : super(
          pgPool,
          (input) => pgPool.query(
            'INSERT INTO contacts (fullName, email, phone, plan) VALUES (@fullName, @email, @phone, @plan);',
            substitutionValues: <String, dynamic>{
              'fullName': input.fullName,
              'email': input.email,
              'phone': input.phone,
              'plan': input.plan,
            },
          ),
        );
}
