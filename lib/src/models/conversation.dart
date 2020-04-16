import 'dart:convert';

import 'package:backend/src/models/message.dart';
import 'package:meta/meta.dart';

@immutable
class Conversation {
  final String id;
  final String subject;
  final String avatar;
  final Set<String> users;
  final Set<String> admins;
  final List<Message> messages = [];

  Conversation(this.id, this.subject, this.avatar, this.admins, this.users);

  factory Conversation.fromDatabase(List<dynamic> data) {
    return Conversation(
      data[0] as String,
      data[1] as String,
      data[2] as String,
      Set<String>.from((json.decode(data[3] as String) as List).cast<String>()),
      Set<String>.from((json.decode(data[4] as String) as List).cast<String>()),
    );
  }

  Map<String, dynamic> toJson({bool putMessages = false}) => <String, dynamic>{
        'id': id,
        'admins': admins.toList(growable: false),
        'users': users.toList(growable: false),
        if (subject != null) 'subject': subject,
        if (avatar != null) 'avatar': avatar,
        if (putMessages) 'messages': messages.map((element) => element.toJson()).toList(growable: false)
      };

  @override
  String toString() => 'Conversation{ $id $subject $avatar ${admins.toList()} ${users.toList()} $messages }';
}
