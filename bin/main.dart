import 'dart:io';

import 'package:backend/backend.dart';
import 'package:logging/logging.dart';
import 'package:postgres_pool/postgres_pool.dart';
import 'package:retry/retry.dart';
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
    settings: PgPoolSettings()
      ..concurrency = 100
      ..retryOptions = RetryOptions(),
  );

  final fromDatabase = generateFromDatabase(postgresPool);
  final toDatabase = generateToDatabase(postgresPool);

  final contactRpcs = generateContactRpcs(fromDatabase, toDatabase);
  final projectRpcs = generateProjectRpcs(fromDatabase, toDatabase);
  final messageRpcs = generateMessageRpcs(fromDatabase, toDatabase);
  final messagesRpcs = generateMessagesRpcs(fromDatabase, toDatabase);
  final conversationRpcs = generateConversationRpcs(fromDatabase, toDatabase);
  final conversationsRpcs = generateConversationsRpcs(fromDatabase, toDatabase);
  final accountRpcs = generateAccountRpcs(fromDatabase, toDatabase);
  final tokenRpcs = generateTokenRpcs(fromDatabase, toDatabase);
  final userRpcs = generateUserRpcs(fromDatabase, toDatabase);

  final rpcs = generateRpcs(
    messageRpcs,
    messagesRpcs,
    conversationRpcs,
    conversationsRpcs,
    contactRpcs,
    projectRpcs,
    accountRpcs,
    tokenRpcs,
    userRpcs,
  );

  SecurityContext securityContext;
  if (Platform.environment['USE_SSL'] == 'true') {
    securityContext = SecurityContext()
      ..useCertificateChain('/etc/letsencrypt/live/staging.api.dalk.io/fullchain.pem')
      ..usePrivateKey('/etc/letsencrypt/live/staging.api.dalk.io/privkey.pem');
  }

  final backend = Backend(rpcs);
  final server = await shelf_io.serve(
    backend.handler,
    '0.0.0.0',
    443,
    securityContext: securityContext,
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
      GetAccountByEmailFromDatabase(pgPool),
      GetTokenFromDatabase(pgPool),
      GetAccountByEmailAndPasswordFromDatabase(pgPool),
      GetProjectByIdFromDatabase(pgPool),
      GetUserByIdFromDatabase(pgPool),
      DeleteTokenFromDatabase(pgPool),
      GetAccountByIdFromDatabase(pgPool),
      GetConversationsForProjectFromDatabase(pgPool),
    );

ToDatabase generateToDatabase(PgPool pgPool) => ToDatabase(
      SaveContactToDatabase(pgPool),
      SaveConversationToDatabase(pgPool),
      UpdateConversationLastUpdateToDatabase(pgPool),
      UpdateConversationSubjectAndAvatarToDatabase(pgPool),
      UpdateMessageStatusToDatabase(pgPool),
      SaveMessageToDatabase(pgPool),
      SaveAccountToDatabase(pgPool),
      SaveProjectToDatabase(pgPool),
      SaveTokenToDatabase(pgPool),
      SaveUserToDatabase(pgPool),
      UpdateUserByIdFromDatabase(pgPool),
      UpdateProjectToDatabase(pgPool),
      UpdateAccountToDatabase(pgPool),
    );

MessageRpcs generateMessageRpcs(FromDatabase from, ToDatabase to) => MessageRpcs(
      GetMessageById(from.getMessageByIdFromDatabase),
      SaveMessage(to.saveMessageToDatabase),
      UpdateMessageStatus(to.updateMessageStatusToDatabase),
    );

MessagesRpcs generateMessagesRpcs(FromDatabase from, ToDatabase to) => MessagesRpcs(GetMessagesForConversation(from.getMessagesForConversationFromDatabase));

ConversationRpcs generateConversationRpcs(FromDatabase from, ToDatabase to) => ConversationRpcs(
      GetConversationById(
        from.getConversationByIdFromDatabase,
        GetMessagesForConversation(from.getMessagesForConversationFromDatabase),
        GetUserById(from.getUserByIdFromDatabase),
      ),
      SaveConversation(to.saveConversationToDatabase),
      UpdateConversationLastUpdate(to.updateConversationLastUpdateToDatabase),
      UpdateConversationSubjectAndAvatar(to.updateConversationSubjectAndAvatarToDatabase),
      GetNumberOfMessageForConversation(from.getNumberOfMessageForConversationFromDatabase),
    );

ConversationsRpcs generateConversationsRpcs(FromDatabase from, ToDatabase to) => ConversationsRpcs(
      GetConversationsForUser(
        from.getConversationsForUserFromDatabase,
        from.getLastMessageForConversationFromDatabase,
        GetUserById(from.getUserByIdFromDatabase),
      ),
      GetConversationsForProject(
        from.getConversationsForProjectFromDatabase,
        GetUserById(from.getUserByIdFromDatabase),
        from.getLastMessageForConversationFromDatabase,
      ),
    );

ContactRpcs generateContactRpcs(FromDatabase from, ToDatabase to) => ContactRpcs(SaveContact(to.saveContactToDatabase));

ProjectRpcs generateProjectRpcs(FromDatabase from, ToDatabase to) => ProjectRpcs(
      GetProjectByKey(from.getProjectByKeyFromDatabase),
      SaveProject(to.saveProjectToDatabase),
      GetProjectById(from.getProjectByIdFromDatabase),
      UpdateProject(to.updateProjectToDatabase),
    );

AccountRpcs generateAccountRpcs(FromDatabase from, ToDatabase to) => AccountRpcs(
      SaveAccount(to.saveAccountToDatabase),
      GetAccountByEmail(from.getAccountByEmailFromDatabase),
      GetAccountByEmailAndPassword(from.getAccountByEmailAndPasswordFromDatabase),
      GetAccountById(from.getAccountById),
      UpdateAccount(to.updateAccountToDatabase),
    );

TokenRpcs generateTokenRpcs(FromDatabase from, ToDatabase to) => TokenRpcs(
      SaveToken(to.saveTokenToDatabase),
      GetToken(from.getTokenFromDatabase),
      DeleteToken(from.deleteTokenFromDatabase),
    );

UserRpcs generateUserRpcs(FromDatabase from, ToDatabase to) => UserRpcs(
      SaveUser(to.saveUserToDatabase),
      GetUserById(from.getUserByIdFromDatabase),
      UpdateUserById(to.updateUserByIdFromDatabase),
    );

Rpcs generateRpcs(
  MessageRpcs messageRpcs,
  MessagesRpcs messagesRpcs,
  ConversationRpcs conversationRpcs,
  ConversationsRpcs conversationsRpcs,
  ContactRpcs contactRpcs,
  ProjectRpcs projectRpcs,
  AccountRpcs accountRpcs,
  TokenRpcs tokenRpcs,
  UserRpcs userRpcs,
) =>
    Rpcs(
      messageRpcs,
      messagesRpcs,
      conversationRpcs,
      conversationsRpcs,
      contactRpcs,
      projectRpcs,
      accountRpcs,
      tokenRpcs,
      userRpcs,
    );
