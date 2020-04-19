import 'dart:io';

import 'package:backend/src/models/project.dart';
import 'package:postgres_pool/postgres_pool.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

void main(List<String> arguments) async {
  if (arguments.length != 1) {
    print('this script take only one parameters which is the project name');
    exit(1);
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

  final uuid = Uuid(options: <String, dynamic>{'grng': UuidUtil.cryptoRNG});
  final groupLimitation = -1;
  final projectName = arguments.first;

  final prodKey = '${projectName}_prod_${uuid.v1(options: <String, dynamic>{
    'positionalArgs': [1]
  })}';
  final prodSecret = '${projectName}_prod_${uuid.v1(options: <String, dynamic>{
    'positionalArgs': [2]
  })}';

  final devKey = '${projectName}_dev_${uuid.v1(options: <String, dynamic>{
    'positionalArgs': [4]
  })}';
  final devSecret = '${projectName}_dev_${uuid.v1(options: <String, dynamic>{
    'positionalArgs': [8]
  })}';

  final project = Project(
    name: arguments.first,
    production: ProjectInformations(
      prodKey,
      prodSecret,
      groupLimitation: groupLimitation,
    ),
    development: ProjectInformations(
      devKey,
      devSecret,
      groupLimitation: groupLimitation,
    ),
  );

  print(project);

  await pg.query(
    '''INSERT INTO projects (
      name,
  productionKey, 
  productionSecret, 
  productionWebhook, 
  developmentKey,
  developmentSecret,
  developmentWebhook,
  groupLimitation
) VALUES (@name, @productionKey, @productionSecret, @productionWebhook, @developmentKey, @developmentSecret, @developmentWebhook, @groupLimitation)''',
    substitutionValues: <String, dynamic>{
      'name': project.name,
      'productionKey': project.production.key,
      'productionSecret': project.production.secret,
      'productionWebhook': project.production.webhook,
      'developmentKey': project.development.key,
      'developmentSecret': project.development.secret,
      'developmentWebhook': project.development.webhook,
      'groupLimitation': project.development.groupLimitation,
    },
  );

  await pg.close();
}
