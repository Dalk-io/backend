import 'package:backend/src/data/message/message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

@freezed
abstract class GetLastMessageForConversationParameters with _$GetLastMessageForConversationParameters {
  const factory GetLastMessageForConversationParameters(String projectId, String conversationId, String senderId) = _GetLastMessageForConversationParameters;
}

@freezed
abstract class GetMessageByIdParameters with _$GetMessageByIdParameters {
  const factory GetMessageByIdParameters(String projectId, String messageId) = _GetMessageByIdParameters;
}

@freezed
abstract class SaveMessageParameters with _$SaveMessageParameters {
  const factory SaveMessageParameters(String id, String projectId, String conversationId, String senderId, String text, List<MessageStateByUserData> states) =
      _SaveMessageParameters;
}

@freezed
abstract class UpdateMessageStateParameters with _$UpdateMessageStateParameters {
  const factory UpdateMessageStateParameters(String projectId, String conversationId, String messageId, List<MessageStateByUserData> states) =
      _UpdateMessageStateParameters;
}
