import 'package:backend/backend.dart';

void main(List<String> arguments) async {
  final pg = getPgPool(arguments.first);

  await pg.execute('ALTER TABLE conversations RENAME COLUMN lastUpdate TO lastMessageCreatedAt;');

  await pg.close();
}
