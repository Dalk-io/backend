import 'package:backend/backend.dart';

import 'src/migrations.dart';

void main(List<String> arguments) async {
  final pg = getPgPool(arguments.first);

  final versionResult = await pg.query('SELECT * FROM database_version');
  final version = versionResult.first.first as int;

  var needUpgrade = false;
  for (final migration in migrations) {
    if (migration.version == version) {
      for (final sqlCommand in migration.sqlCommands) {
        await pg.execute(sqlCommand);
      }
      needUpgrade = true;
    }
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
