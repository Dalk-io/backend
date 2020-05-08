//  ignore_for_file: avoid_print

import 'package:backend/backend.dart';

void main() async {
  final pg = getPgPool('production');

  final results = await pg.query('SELECT * FROM users WHERE projectId = \'dev_094b5c50-8344-11ea-c31d-39a75c9c99e5\'');
  print(results);

  await pg.close();
}
