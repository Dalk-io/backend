import 'package:backend/backend.dart';
import 'package:backend/src/databases/conversation/get_conversation_by_id.dart';
import 'package:backend/src/databases/conversation/get_number_of_message_for_conversation.dart';
import 'package:backend/src/databases/conversations/get_conversations_for_project.dart';
import 'package:backend/src/databases/conversations/get_conversations_for_user.dart';
import 'package:backend/src/databases/message/get_last_message_for_conversation.dart';
import 'package:backend/src/databases/message/get_message_by_id.dart';
import 'package:backend/src/databases/messages/get_messages_for_conversation.dart';
import 'package:backend/src/databases/project/get_project_by_key.dart';
import 'package:backend/src/databases/user/get_user_by_id.dart';

class FromDatabase {
  final GetConversationByIdFromDatabase getConversationByIdFromDatabase;
  final GetNumberOfMessageForConversationFromDatabase getNumberOfMessageForConversationFromDatabase;

  final GetConversationsForUserFromDatabase getConversationsForUserFromDatabase;
  final GetConversationsForProjectFromDatabase getConversationsForProjectFromDatabase;

  final GetLastMessageForConversationFromDatabase getLastMessageForConversationFromDatabase;
  final GetMessageByIdFromDatabase getMessageByIdFromDatabase;
  final GetMessagesForConversationFromDatabase getMessagesForConversationFromDatabase;

  final GetProjectByKeyFromDatabase getProjectByKeyFromDatabase;
  final GetProjectByIdFromDatabase getProjectByIdFromDatabase;

  final GetAccountByEmailFromDatabase getAccountByEmailFromDatabase;
  final GetAccountByEmailAndPasswordFromDatabase getAccountByEmailAndPasswordFromDatabase;
  final GetAccountByIdFromDatabase getAccountById;

  final GetTokenFromDatabase getTokenFromDatabase;
  final DeleteTokenFromDatabase deleteTokenFromDatabase;

  final GetUserByIdFromDatabase getUserByIdFromDatabase;

  FromDatabase(
    this.getConversationByIdFromDatabase,
    this.getNumberOfMessageForConversationFromDatabase,
    this.getConversationsForUserFromDatabase,
    this.getLastMessageForConversationFromDatabase,
    this.getMessageByIdFromDatabase,
    this.getMessagesForConversationFromDatabase,
    this.getProjectByKeyFromDatabase,
    this.getAccountByEmailFromDatabase,
    this.getTokenFromDatabase,
    this.getAccountByEmailAndPasswordFromDatabase,
    this.getProjectByIdFromDatabase,
    this.getUserByIdFromDatabase,
    this.deleteTokenFromDatabase,
    this.getAccountById,
    this.getConversationsForProjectFromDatabase,
  );
}
