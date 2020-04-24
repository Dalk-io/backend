import 'package:backend/src/data/project/project.dart';
import 'package:postgres_pool/postgres_pool.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

void main(List<String> arguments) async {
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
  final secure = true;

  final devKey = 'dev_${uuid.v1(options: <String, dynamic>{
    'positionalArgs': [4]
  })}';
  final devSecret = 'dev_${uuid.v1(options: <String, dynamic>{
    'positionalArgs': [8]
  })}';

  final project = ProjectsData(
    ProjectEnvironment(devKey, devSecret),
    SubscriptionType.starter,
    groupLimitation: groupLimitation,
    isSecure: secure,
  );

  print(project);

  await pg.query(
    '''INSERT INTO projects (
  productionKey, 
  productionSecret, 
  productionWebHook, 
  developmentKey,
  developmentSecret,
  developmentWebHook,
  groupLimitation,
  secure
) VALUES (@name, @productionKey, @productionSecret, @productionWebHook, @developmentKey, @developmentSecret, @developmentWebHook, @groupLimitation, @secure)''',
    substitutionValues: <String, dynamic>{
      'productionKey': project.production?.key,
      'productionSecret': project.production?.secret,
      'productionWebHook': project.production?.webHook,
      'developmentKey': project.development.key,
      'developmentSecret': project.development.secret,
      'developmentWebHook': project.development.webHook,
      'groupLimitation': project.groupLimitation,
      'secure': project.isSecure,
    },
  );

  await pg.close();
}
