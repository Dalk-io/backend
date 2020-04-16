import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

@freezed
abstract class GetMessagesForConversationParameters with _$GetMessagesForConversationParameters {
  const factory GetMessagesForConversationParameters(String projectId, String conversationId, int from, int to) = _GetMessagesForConversationParameters;
}
