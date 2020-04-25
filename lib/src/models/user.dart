import 'package:backend/src/data/user/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:meta/meta.dart';

@immutable
class User {
  final Peer peer;
  final UserData data;

  User(this.peer, this.data);

  @override
  int get hashCode => data.id.hashCode;

  @override
  bool operator ==(Object other) => other is User && other.data.id == data.id;

  factory User.fromDatabase(UserData userData) {
    return User(null, userData);
  }

  void onConversationCreated(Map<String, dynamic> data) {
    peer?.sendRequest('onConversationCreated', data);
  }

  void receiveMessage(String conversationId, Map<String, dynamic> data) {
    peer?.sendRequest('receiveMessage$conversationId', data);
  }

  void updateMessageStatus(String conversationId, Map<String, dynamic> data) {
    peer?.sendRequest('updateMessageStatus$conversationId', data);
  }

  Map<String, dynamic> toJson() => data.toJson()..remove('password');

  @override
  String toString() => data.toString();
}
