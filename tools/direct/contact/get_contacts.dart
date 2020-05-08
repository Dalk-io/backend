//  ignore_for_file: avoid_print

import 'package:backend/backend.dart';

void main() async {
  final pg = getPgPool('production');

  final results = await pg.query('SELECT * FROM contacts');

  for (final result in results) {
    print(result);
  }

  await pg.close();
}
