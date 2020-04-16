import 'package:backend/src/rpc/conversations/get_conversations_for_user.dart';
import 'package:meta/meta.dart';

@immutable
class ConversationsRpcs {
  final GetConversationsForUser getConversationsForUser;

  ConversationsRpcs(this.getConversationsForUser);
}
