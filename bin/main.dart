import 'package:backend/backend.dart';
import 'package:backend/src/rpc/contact/save_contact.dart';
import 'package:logging/logging.dart';
import 'package:postgres_pool/postgres_pool.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main(List<String> arguments) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) => print('${record.time.toIso8601String()} ${record.level.name} ${record.loggerName}: ${record.message}'));
  final _logger = Logger('main');

  final postgresPool = PgPool(
    PgEndpoint(
      host: '51.159.26.58',
      port: 10480,
      database: 'rdb',
      username: 'dalk',
      password: 'MmA1@<s|cV#"\'0BX}[zJ4',
      requireSsl: true,
    ),
    settings: PgPoolSettings()..concurrency = 100,
  );

  final saveContactToDatabase = SaveContactToDatabase(postgresPool);

  final getConversationByIdFromDatabase = GetConversationByIdFromDatabase(postgresPool);
  final saveConversationToDatabase = SaveConversationToDatabase(postgresPool);
  final updateConversationLastUpdateToDatabase = UpdateConversationLastUpdateToDatabase(postgresPool);
  final updateConversationSubjectAndAvatarToDatabase = UpdateConversationSubjectAndAvatarToDatabase(postgresPool);
  final getNumberOfMessageForConversationFromDatabase = GetNumberOfMessageForConversationFromDatabase(postgresPool);

  final getConversationsForUserFromDatabase = GetConversationsForUserFromDatabase(postgresPool);

  final getLastMessageForConversationFromDatabase = GetLastMessageForConversationFromDatabase(postgresPool);
  final getMessageByIdFromDatabase = GetMessageByIdFromDatabase(postgresPool);
  final saveMessageToDatabase = SaveMessageToDatabase(postgresPool);
  final updateMessageStateToDatabase = UpdateMessageStateToDatabase(postgresPool);

  final getMessagesForConversationFromDatabase = GetMessagesForConversationFromDatabase(postgresPool);

  final getProjectByKeyFromDatabase = GetProjectByKeyFromDatabase(postgresPool);

  final saveContact = SaveContact(saveContactToDatabase);

  final getMessagesForConversation = GetMessagesForConversation(getMessagesForConversationFromDatabase);
  final messagesRpcs = MessagesRpcs(getMessagesForConversation);

  final getMessageById = GetMessageById(getMessageByIdFromDatabase);
  final saveMessage = SaveMessage(saveMessageToDatabase);
  final updateMessageState = UpdateMessageState(updateMessageStateToDatabase);
  final messageRpcs = MessageRpcs(getMessageById, saveMessage, updateMessageState);

  final getUserConversations = GetConversationsForUser(getConversationsForUserFromDatabase, getLastMessageForConversationFromDatabase);
  final conversationsRpcs = ConversationsRpcs(getUserConversations);

  final getConversationById = GetConversationById(getConversationByIdFromDatabase, getMessagesForConversation);
  final saveConversation = SaveConversation(saveConversationToDatabase);
  final updateConversationLastUpdate = UpdateConversationLastUpdate(updateConversationLastUpdateToDatabase);
  final updateConversationSubjectAndAvatar = UpdateConversationSubjectAndAvatar(updateConversationSubjectAndAvatarToDatabase);
  final getNumberOfMessageForConversation = GetNumberOfMessageForConversation(getNumberOfMessageForConversationFromDatabase);
  final conversationRpcs = ConversationRpcs(
    getConversationById,
    saveConversation,
    updateConversationLastUpdate,
    updateConversationSubjectAndAvatar,
    getNumberOfMessageForConversation,
  );

  final getProjectByKey = GetProjectByKey(getProjectByKeyFromDatabase);

  final backend = Backend(conversationRpcs, conversationsRpcs, messageRpcs, messagesRpcs, saveContact, getProjectByKey);
  final server = await shelf_io.serve(
    backend.handler,
    '0.0.0.0',
    443,
  );

  _logger.info('listening http://${server.address.address}:${server.port}');
}
