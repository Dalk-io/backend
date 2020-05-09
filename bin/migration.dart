import 'package:backend/backend.dart';
import 'package:postgres_pool/postgres_pool.dart';

void main(List<String> arguments) async {
  final pg = getPgPool(arguments.first);

  final versionResult = await pg.query('SELECT * FROM database_version');
  final version = versionResult.first.first as int;

  var needUpgrade = false;
  if (version == 1) {
    needUpgrade = await v1ToV2(pg);
  }

  if (needUpgrade) {
    await pg.execute(
      'UPDATE database_version SET version = @newVersion WHERE version = @oldVersion',
      substitutionValues: {
        'oldVersion': version,
        'newVersion': version + 1,
      },
    );
  }

  await pg.close();
}

Future<bool> v1ToV2(PgPool pg) async {
  await pg.execute('ALTER TABLE conversations RENAME COLUMN lastUpdate TO lastMessageCreatedAt;');
  return true;
}
