//  ignore_for_file: avoid_print

import 'package:backend/backend.dart';

void main() async {
  final pg = getPgPool('development');

  final results = await pg.query('SELECT * FROM projects');

  for (final result in results) {
    print(result);
  }

  await pg.close();
}
