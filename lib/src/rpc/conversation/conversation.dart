import 'package:backend/src/rpc/conversation/get_conversation_by_id.dart';
import 'package:backend/src/rpc/conversation/save_conversation.dart';
import 'package:backend/src/rpc/conversation/update_conversation_last_update.dart';
import 'package:backend/src/rpc/conversation/update_conversation_subject_and_avatar.dart';
import 'package:meta/meta.dart';

@immutable
class ConversationRpcs {
  final GetConversationById getConversationById;
  final SaveConversation saveConversation;
  final UpdateConversationLastUpdate updateConversationLastUpdate;
  final UpdateConversationSubjectAndAvatar updateConversationSubjectAndAvatar;

  ConversationRpcs(this.getConversationById, this.saveConversation, this.updateConversationLastUpdate, this.updateConversationSubjectAndAvatar);
}
