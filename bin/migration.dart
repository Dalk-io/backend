import 'dart:io';

import 'package:backend/backend.dart';

import 'src/migrations.dart';

void main() async {
  final pg = getPgPool(Platform.environment['DATABASE_NAME']);

  final versionResult = await pg.query('SELECT * FROM database_version');
  final currentVersion = versionResult.first.first as int;

  var needUpgrade = false;
  var version = currentVersion;
  for (final migration in migrations) {
    if (migration.version == version) {
      for (final sqlCommand in migration.sqlCommands) {
        await pg.execute(sqlCommand);
      }
      needUpgrade = true;
      version = migration.version + 1;
    }
  }

  if (needUpgrade) {
    await pg.execute(
      'UPDATE database_version SET version = @newVersion WHERE version = @oldVersion',
      substitutionValues: {
        'oldVersion': currentVersion,
        'newVersion': version,
      },
    );
  }

  await pg.close();
}
