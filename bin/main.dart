import 'package:backend/backend.dart';
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

  final fromDatabase = generateFromDatabase(postgresPool);
  final toDatabase = generateToDatabase(postgresPool);

  final contactRpcs = generateContactRpcs(fromDatabase, toDatabase);
  final projectRpcs = generateProjectRpcs(fromDatabase, toDatabase);

  final messageRpcs = generateMessageRpcs(fromDatabase, toDatabase);
  final messagesRpcs = generateMessagesRpcs(fromDatabase, toDatabase);
  final conversationRpcs = generateConversationRpcs(fromDatabase, toDatabase);
  final conversationsRpcs = generateConversationsRpcs(fromDatabase, toDatabase);

  final rpcs = generateRpcs(messageRpcs, messagesRpcs, conversationRpcs, conversationsRpcs, contactRpcs, projectRpcs);

  final backend = Backend(rpcs);
  final server = await shelf_io.serve(
    backend.handler,
    '0.0.0.0',
    443,
  );

  _logger.info('listening http://${server.address.address}:${server.port}');
}

FromDatabase generateFromDatabase(PgPool pgPool) => FromDatabase(
      GetConversationByIdFromDatabase(pgPool),
      GetNumberOfMessageForConversationFromDatabase(pgPool),
      GetConversationsForUserFromDatabase(pgPool),
      GetLastMessageForConversationFromDatabase(pgPool),
      GetMessageByIdFromDatabase(pgPool),
      GetMessagesForConversationFromDatabase(pgPool),
      GetProjectByKeyFromDatabase(pgPool),
    );

ToDatabase generateToDatabase(PgPool pgPool) => ToDatabase(
      SaveContactToDatabase(pgPool),
      SaveConversationToDatabase(pgPool),
      UpdateConversationLastUpdateToDatabase(pgPool),
      UpdateConversationSubjectAndAvatarToDatabase(pgPool),
      UpdateMessageStateToDatabase(pgPool),
      SaveMessageToDatabase(pgPool),
    );

MessageRpcs generateMessageRpcs(FromDatabase from, ToDatabase to) => MessageRpcs(
      GetMessageById(from.getMessageByIdFromDatabase),
      SaveMessage(to.saveMessageToDatabase),
      UpdateMessageState(to.updateMessageStateToDatabase),
    );

MessagesRpcs generateMessagesRpcs(FromDatabase from, ToDatabase to) => MessagesRpcs(GetMessagesForConversation(from.getMessagesForConversationFromDatabase));

ConversationRpcs generateConversationRpcs(FromDatabase from, ToDatabase to) => ConversationRpcs(
      GetConversationById(from.getConversationByIdFromDatabase, GetMessagesForConversation(from.getMessagesForConversationFromDatabase)),
      SaveConversation(to.saveConversationToDatabase),
      UpdateConversationLastUpdate(to.updateConversationLastUpdateToDatabase),
      UpdateConversationSubjectAndAvatar(to.updateConversationSubjectAndAvatarToDatabase),
      GetNumberOfMessageForConversation(from.getNumberOfMessageForConversationFromDatabase),
    );

ConversationsRpcs generateConversationsRpcs(FromDatabase from, ToDatabase to) => ConversationsRpcs(
      GetConversationsForUser(from.getConversationsForUserFromDatabase, from.getLastMessageForConversationFromDatabase),
    );

ContactRpcs generateContactRpcs(FromDatabase from, ToDatabase to) => ContactRpcs(SaveContact(to.saveContactToDatabase));

ProjectRpcs generateProjectRpcs(FromDatabase from, ToDatabase to) => ProjectRpcs(GetProjectByKey(from.getProjectByKeyFromDatabase));

Rpcs generateRpcs(
  MessageRpcs messageRpcs,
  MessagesRpcs messagesRpcs,
  ConversationRpcs conversationRpcs,
  ConversationsRpcs conversationsRpcs,
  ContactRpcs contactRpcs,
  ProjectRpcs projectRpcs,
) =>
    Rpcs(
      messageRpcs,
      messagesRpcs,
      conversationRpcs,
      conversationsRpcs,
      contactRpcs,
      projectRpcs,
    );
