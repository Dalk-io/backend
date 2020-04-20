import 'package:backend/src/rpc/contact/contact.dart';
import 'package:backend/src/rpc/conversation/conversation.dart';
import 'package:backend/src/rpc/conversations/conversations.dart';
import 'package:backend/src/rpc/message/message.dart';
import 'package:backend/src/rpc/messages/messages.dart';
import 'package:backend/src/rpc/project/project.dart';

class Rpcs {
  final MessageRpcs messageRpcs;
  final MessagesRpcs messagesRpcs;
  final ConversationRpcs conversationRpcs;
  final ConversationsRpcs conversationsRpcs;
  final ContactRpcs contactRpcs;
  final ProjectRpcs projectRpcs;

  Rpcs(this.messageRpcs, this.messagesRpcs, this.conversationRpcs, this.conversationsRpcs, this.contactRpcs, this.projectRpcs);
}
