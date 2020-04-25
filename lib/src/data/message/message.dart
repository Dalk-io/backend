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
    DateTime timestamp,
    List<MessageStateByUserData> states,
  ) = _MessageData;

  factory MessageData.fromJson(Map<String, dynamic> json) => _$MessageDataFromJson(json);

  factory MessageData.fromDatabase(List<dynamic> data) {
    final states = (json.decode(data[6] as String) as List)
        .cast<Map>()
        .cast<Map<String, dynamic>>()
        .map((state) => MessageStateByUserData(state['id'] as String, MessageState.values[state['state'] as int]))
        .toList();
    return MessageData(
      data[0] as String,
      data[1] as String,
      data[2] as String,
      data[3] as String,
      data[4] as String,
      data[5] as DateTime,
      states,
    );
  }
}

String computeMessageState(MessageData message) => messageStateToString(MessageState.values[
    message.states.where((state) => state.id != message.senderId).fold<int>(0, (value, state) => (value < state.state.index) ? state.state.index : value)]);

List<Map<String, dynamic>> computeMessageStates(MessageData message) =>
    message.states.where((state) => state.id != message.senderId).map((state) => state.toJson()).toList();

enum MessageState {
  sent,
  received,
  seen,
}

MessageState messageStateFromString(String state) => _$enumDecodeNullable(_$MessageStateEnumMap, state);
String messageStateToString(MessageState state) => _$MessageStateEnumMap[state];

@freezed
abstract class MessageStateByUserData with _$MessageStateByUserData {
  @JsonSerializable(explicitToJson: true)
  const factory MessageStateByUserData(String id, MessageState state) = _MessageStateByUserData;

  factory MessageStateByUserData.fromJson(Map<String, dynamic> json) => _$MessageStateByUserDataFromJson(json);
}
