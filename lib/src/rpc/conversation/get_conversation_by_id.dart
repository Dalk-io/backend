import 'package:backend/backend.dart';
import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/endpoint.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:backend/src/rpc/messages/get_messages_for_conversation.dart';
import 'package:backend/src/rpc/messages/parameters.dart';
import 'package:backend/src/utils/conversations_from_database.dart';
import 'package:meta/meta.dart';

@immutable
class GetConversationById extends Endpoint<GetConversationByIdParameters, ConversationData> {
  final GetConversationByIdFromDatabase _getConversationByIdFromDatabase;
  final GetMessagesForConversation _getMessagesForConversation;
  final GetUserById _getUserById;

  GetConversationById(this._getConversationByIdFromDatabase, this._getMessagesForConversation, this._getUserById);

  @override
  Future<ConversationData> request(GetConversationByIdParameters input) async {
    final conversationData = await _getConversationByIdFromDatabase.request(input);
    if (conversationData.isEmpty) {
      return null;
    }
    final result = conversationData.first;
    final conversation = await conversationFromDatabase(result, input.projectId, _getUserById);
    var messages = <MessageData>[];
    messages = await _getMessagesForConversation.request(GetMessagesForConversationParameters(
      input.projectId,
      input.conversationId,
      from: input.from,
      take: input.take,
    ));
    return conversation.copyWith(messages: messages);
  }
}
