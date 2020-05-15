import '../models/migration.dart';

const v1ToV2Migration = Migration(
  1,
  [
    'ALTER TABLE conversations RENAME COLUMN lastUpdate TO lastMessageCreatedAt;',
  ],
);
