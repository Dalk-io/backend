import 'package:backend/src/models/conversation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

@freezed
abstract class GetConversationByIdParameters with _$GetConversationByIdParameters {
  const factory GetConversationByIdParameters(String projectId, String conversationId, bool getMessages) = _GetConversationByIdParameters;
}

@freezed
abstract class SaveConversationParameters with _$SaveConversationParameters {
  const factory SaveConversationParameters(String projectId, Conversation conversation) = _SaveConversationParameters;
}

@freezed
abstract class UpdateConversationLastUpdateParameters with _$UpdateConversationLastUpdateParameters {
  const factory UpdateConversationLastUpdateParameters(String projectId, String conversationId) = _UpdateConversationLastUpdateParameters;
}

@freezed
abstract class UpdateConversationSubjectAndAvatarParameters with _$UpdateConversationSubjectAndAvatarParameters {
  const factory UpdateConversationSubjectAndAvatarParameters(
    String projectId,
    String conversationId,
    @nullable String subject,
    @nullable String avatar,
  ) = _UpdateConversationSubjectAndAvatarParameters;
}
