import 'package:backend/src/rpc/messages/get_messages_for_conversation.dart';
import 'package:meta/meta.dart';

@immutable
class MessagesRpcs {
  final GetMessagesForConversation getMessagesForConversation;

  MessagesRpcs(this.getMessagesForConversation);
}
