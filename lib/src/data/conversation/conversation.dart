import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/data/user/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
abstract class ConversationData with _$ConversationData {
  @JsonSerializable(explicitToJson: true)
  const factory ConversationData({
    @nullable String id,
    @nullable @JsonKey(includeIfNull: false) String subject,
    @nullable @JsonKey(includeIfNull: false) String avatar,
    @Default(<UserData>[]) List<UserData> admins,
    @Default(<UserData>[]) List<UserData> users,
    @Default(<MessageData>[]) List<MessageData> messages,
    @Default(false) bool isGroup,
  }) = _ConversationData;

  factory ConversationData.fromJson(Map<String, dynamic> json) => _$ConversationDataFromJson(json);
}
