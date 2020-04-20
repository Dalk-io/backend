import 'package:backend/src/databases/contact/save_contact.dart';
import 'package:backend/src/databases/conversation/save_conversation.dart';
import 'package:backend/src/databases/conversation/update_conversation_last_update.dart';
import 'package:backend/src/databases/conversation/update_conversation_subject_and_avatar.dart';
import 'package:backend/src/databases/message/save_message.dart';
import 'package:backend/src/databases/message/update_message_state.dart';

class ToDatabase {
  final SaveContactToDatabase saveContactToDatabase;

  final SaveConversationToDatabase saveConversationToDatabase;
  final UpdateConversationLastUpdateToDatabase updateConversationLastUpdateToDatabase;
  final UpdateConversationSubjectAndAvatarToDatabase updateConversationSubjectAndAvatarToDatabase;

  final UpdateMessageStateToDatabase updateMessageStateToDatabase;

  final SaveMessageToDatabase saveMessageToDatabase;

  ToDatabase(
    this.saveContactToDatabase,
    this.saveConversationToDatabase,
    this.updateConversationLastUpdateToDatabase,
    this.updateConversationSubjectAndAvatarToDatabase,
    this.updateMessageStateToDatabase,
    this.saveMessageToDatabase,
  );
}
