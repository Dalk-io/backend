//  ignore_for_file: avoid_print

import 'package:postgres_pool/postgres_pool.dart';

void main(List<String> arguments) async {
  if (arguments.length != 2) {
    print('This program take 2 arguments the project id and the new plan [starter, complete ,god]');
    return;
  }
  final projectId = int.tryParse(arguments.first);
  final plan = arguments.last;
  if (!['starter', 'complete', 'god'].contains(plan)) {
    print('This plan is not supported!');
    return;
  }

  final pg = PgPool(
    PgEndpoint(
      host: '51.159.26.58',
      port: 10480,
      database: 'rdb',
      username: 'dalk',
      password: 'MmA1@<s|cV#"\'0BX}[zJ4',
      requireSsl: true,
    ),
    settings: PgPoolSettings()..concurrency = 10,
  );

  var groupLimitation = 5;
  if (plan == 'complete') {
    groupLimitation = 100;
  } else if (plan == 'god') {
    groupLimitation = -1;
  }

  await pg.query(
    'UPDATE projects SET groupLimitation = @groupLimitation WHERE id = @id',
    substitutionValues: <String, dynamic>{
      'groupLimitation': groupLimitation,
      'id': projectId,
    },
  );

  await pg.close();
}
