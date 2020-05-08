import 'package:backend/backend.dart';

void main() async {
  final pg = getPgPool('production');

  await pg.execute('DELETE FROM accounts;');

  await pg.close();
}
