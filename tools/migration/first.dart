import 'package:backend/backend.dart';

void main() async {
  final pg = getPgPool('production');

  await pg.execute('ALTER TABLE messages ADD COLUMN metadata json;');
  await pg.execute('ALTER TABLE messages ADD COLUMN modifiedAt TIMESTAMPTZ;');
  await pg.execute('ALTER TABLE messages RENAME COLUMN timestamp TO createdAt;');

  await pg.close();
}
