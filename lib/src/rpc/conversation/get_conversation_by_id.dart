import 'package:backend/backend.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/models/conversation.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:backend/src/rpc/messages/get_messages_for_conversation.dart';
import 'package:backend/src/rpc/messages/parameters.dart';
import 'package:meta/meta.dart';

@immutable
class GetConversationById extends Endpoint<GetConversationByIdParameters, Conversation> {
  final GetConversationByIdFromDatabase _getConversationByIdFromDatabase;
  final GetMessagesForConversation _getMessagesForConversation;

  GetConversationById(this._getConversationByIdFromDatabase, this._getMessagesForConversation);

  @override
  Future<Conversation> request(GetConversationByIdParameters input) async {
    final conversationData = await _getConversationByIdFromDatabase.request(input);
    if (conversationData.isEmpty) {
      return null;
    }
    final conversation = Conversation.fromDatabase(conversationData.first);
    if (input.getMessages) {
      final messages = await _getMessagesForConversation.request(GetMessagesForConversationParameters(input.projectId, input.conversationId, 0, -1));
      conversation.messages.addAll(messages);
    }
    return conversation;
  }
}
