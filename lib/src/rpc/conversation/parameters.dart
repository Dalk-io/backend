import 'package:backend/src/data/conversation/conversation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

@freezed
abstract class GetConversationByIdParameters with _$GetConversationByIdParameters {
  const factory GetConversationByIdParameters(String projectId, String conversationId, {@Default(false) bool getMessages}) = _GetConversationByIdParameters;
}

@freezed
abstract class SaveConversationParameters with _$SaveConversationParameters {
  const factory SaveConversationParameters(String projectId, ConversationData conversation) = _SaveConversationParameters;
}

@freezed
abstract class UpdateConversationLastUpdateParameters with _$UpdateConversationLastUpdateParameters {
  const factory UpdateConversationLastUpdateParameters(String projectId, String conversationId) = _UpdateConversationLastUpdateParameters;
}

@freezed
abstract class UpdateConversationSubjectAndAvatarParameters with _$UpdateConversationSubjectAndAvatarParameters {
  const factory UpdateConversationSubjectAndAvatarParameters(
    String projectId,
    String conversationId, {
    @nullable String subject,
    @nullable String avatar,
  }) = _UpdateConversationSubjectAndAvatarParameters;
}

@freezed
abstract class GetNumberOfMessageForConversationParameter with _$GetNumberOfMessageForConversationParameter {
  const factory GetNumberOfMessageForConversationParameter(
    String projectId,
    String conversationId,
  ) = _GetNumberOfMessageForConversationParameter;
}
