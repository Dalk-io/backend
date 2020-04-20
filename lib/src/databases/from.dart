import 'package:backend/backend.dart';
import 'package:backend/src/databases/conversation/get_conversation_by_id.dart';
import 'package:backend/src/databases/conversation/get_number_of_message_for_conversation.dart';
import 'package:backend/src/databases/conversations/get_conversations_for_user.dart';
import 'package:backend/src/databases/message/get_last_message_for_conversation.dart';
import 'package:backend/src/databases/message/get_message_by_id.dart';
import 'package:backend/src/databases/messages/get_messages_for_conversation.dart';
import 'package:backend/src/databases/project/get_project_by_key.dart';

class FromDatabase {
  final GetConversationByIdFromDatabase getConversationByIdFromDatabase;
  final GetNumberOfMessageForConversationFromDatabase getNumberOfMessageForConversationFromDatabase;

  final GetConversationsForUserFromDatabase getConversationsForUserFromDatabase;

  final GetLastMessageForConversationFromDatabase getLastMessageForConversationFromDatabase;
  final GetMessageByIdFromDatabase getMessageByIdFromDatabase;
  final GetMessagesForConversationFromDatabase getMessagesForConversationFromDatabase;

  final GetProjectByKeyFromDatabase getProjectByKeyFromDatabase;

  final GetAccountByEmailFromDatabase getAccountByEmailFromDatabase;

  FromDatabase(
    this.getConversationByIdFromDatabase,
    this.getNumberOfMessageForConversationFromDatabase,
    this.getConversationsForUserFromDatabase,
    this.getLastMessageForConversationFromDatabase,
    this.getMessageByIdFromDatabase,
    this.getMessagesForConversationFromDatabase,
    this.getProjectByKeyFromDatabase,
    this.getAccountByEmailFromDatabase,
  );
}
