import 'dart:convert';

import 'package:meta/meta.dart';

enum MessageState {
  sent,
  received,
  seen,
}

@immutable
class MessageStateByUser {
  final String id;
  final MessageState state;

  MessageStateByUser(this.id, this.state);

  factory MessageStateByUser.fromDatabase(Map<String, dynamic> data) {
    return MessageStateByUser(data['id'] as String, MessageState.values[data['state'] as int]);
  }

  @override
  String toString() => 'MessageStateByUser{ $id, $state }';
}

@immutable
class Message {
  final String projectId;
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final List<MessageStateByUser> states;

  Message(this.projectId, this.id, this.conversationId, this.senderId, this.text, this.timestamp, this.states);

  factory Message.fromDatabase(List<dynamic> data) {
    final states = (json.decode(data[6] as String) as List).cast<Map>().cast<Map<String, dynamic>>();

    return Message(
      data[0] as String,
      '${data[1]}',
      data[2] as String,
      data[3] as String,
      data[4] as String,
      data[5] as DateTime,
      states.map((state) => MessageStateByUser.fromDatabase(state)).toList(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'senderId': senderId,
        if (text != null) 'text': text,
        'timestamp': timestamp.toIso8601String(),
        'state': states.where((state) => state.id != senderId).fold<int>(0, (value, state) => (value < state.state.index) ? state.state.index : value),
        'stateDetails': states.where((state) => state.id != senderId).map((state) => {'userId': state.id, 'state': state.state.index}).toList(),
      };

  @override
  String toString() => 'Message{ $id, $senderId, $text, $timestamp, $states }';
}
