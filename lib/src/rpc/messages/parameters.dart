import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

@freezed
abstract class GetMessagesForConversationParameters with _$GetMessagesForConversationParameters {
  const factory GetMessagesForConversationParameters(String projectId, String conversationId, {@Default(0) int from, @Default(-1) int to}) =
      _GetMessagesForConversationParameters;
}
