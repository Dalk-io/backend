import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
abstract class MessageData with _$MessageData {
  @JsonSerializable(explicitToJson: true)
  const factory MessageData(
    String id,
    @nullable @JsonKey(includeIfNull: false) String projectId,
    @nullable @JsonKey(includeIfNull: false) String conversationId,
    String senderId,
    String text,
    DateTime createdAt,
    List<MessageStatusByUserData> statusDetails, {
    @JsonKey(includeIfNull: false) dynamic metadata,
    @JsonKey(includeIfNull: false) DateTime modifiedAt,
  }) = _MessageData;

  factory MessageData.fromJson(Map<String, dynamic> json) => _$MessageDataFromJson(json);

  factory MessageData.fromDatabase(List<dynamic> data) {
    final statusDetails = (json.decode(data[6] as String) as List)
        .cast<Map>()
        .cast<Map<String, dynamic>>()
        .map((status) => MessageStatusByUserData(status['id'] as String, MessageStatus.values[status['status'] as int]))
        .toList();
    return MessageData(
      data[0] as String,
      data[1] as String,
      data[2] as String,
      data[3] as String,
      data[4] as String,
      data[5] as DateTime,
      statusDetails,
      metadata: json.decode(data[6] as String),
      modifiedAt: data[8] as DateTime,
    );
  }
}

String computeMessageStatus(MessageData message, {bool filter = true}) => messageStatusToString(MessageStatus.values[message.statusDetails
    .where((status) => !filter || status.id != message.senderId)
    .fold<int>(0, (value, status) => (value < status.status.index) ? status.status.index : value)]);

List<Map<String, dynamic>> computeMessageStatusDetails(MessageData message) =>
    message.statusDetails.where((status) => status.id != message.senderId).map((status) => status.toJson()).toList();

enum MessageStatus {
  sent,
  received,
  seen,
}

MessageStatus messageStatusFromString(String status) => _$enumDecodeNullable(_$MessageStatusEnumMap, status);
String messageStatusToString(MessageStatus status) => _$MessageStatusEnumMap[status];

@freezed
abstract class MessageStatusByUserData with _$MessageStatusByUserData {
  @JsonSerializable(explicitToJson: true)
  const factory MessageStatusByUserData(String id, MessageStatus status) = _MessageStatusByUserData;

  factory MessageStatusByUserData.fromJson(Map<String, dynamic> json) => _$MessageStatusByUserDataFromJson(json);
}
