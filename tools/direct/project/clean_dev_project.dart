import 'package:backend/backend.dart';

void main() async {
  final pg = getPgPool('production');

  await pg.execute('DELETE FROM users WHERE projectId LIKE \'dev_%\';');
  await pg.execute('DELETE FROM messages WHERE projectId LIKE \'dev_%\';');
  await pg.execute('DELETE FROM conversations WHERE projectId LIKE \'dev_%\';');

  await pg.close();
}
