import 'package:backend/src/databases/account/save_account.dart';
import 'package:backend/src/databases/account/update_account.dart';
import 'package:backend/src/databases/contact/save_contact.dart';
import 'package:backend/src/databases/conversation/save_conversation.dart';
import 'package:backend/src/databases/conversation/update_conversation_last_update.dart';
import 'package:backend/src/databases/conversation/update_conversation_subject_and_avatar.dart';
import 'package:backend/src/databases/message/save_message.dart';
import 'package:backend/src/databases/message/update_message_status.dart';
import 'package:backend/src/databases/project/save_project.dart';
import 'package:backend/src/databases/project/update_project.dart';
import 'package:backend/src/databases/token/save_token.dart';
import 'package:backend/src/databases/user/save_user.dart';
import 'package:backend/src/databases/user/update_user.dart';

class ToDatabase {
  final SaveContactToDatabase saveContactToDatabase;

  final SaveConversationToDatabase saveConversationToDatabase;
  final UpdateConversationLastUpdateToDatabase updateConversationLastUpdateToDatabase;
  final UpdateConversationSubjectAndAvatarToDatabase updateConversationSubjectAndAvatarToDatabase;

  final UpdateMessageStatusToDatabase updateMessageStatusToDatabase;

  final SaveMessageToDatabase saveMessageToDatabase;

  final SaveAccountToDatabase saveAccountToDatabase;
  final UpdateAccountToDatabase updateAccountToDatabase;

  final SaveProjectToDatabase saveProjectToDatabase;
  final UpdateProjectToDatabase updateProjectToDatabase;

  final SaveTokenToDatabase saveTokenToDatabase;

  final SaveUserToDatabase saveUserToDatabase;
  final UpdateUserByIdFromDatabase updateUserByIdFromDatabase;

  ToDatabase(
    this.saveContactToDatabase,
    this.saveConversationToDatabase,
    this.updateConversationLastUpdateToDatabase,
    this.updateConversationSubjectAndAvatarToDatabase,
    this.updateMessageStatusToDatabase,
    this.saveMessageToDatabase,
    this.saveAccountToDatabase,
    this.saveProjectToDatabase,
    this.saveTokenToDatabase,
    this.saveUserToDatabase,
    this.updateUserByIdFromDatabase,
    this.updateProjectToDatabase,
    this.updateAccountToDatabase,
  );
}
