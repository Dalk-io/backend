import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:meta/meta.dart';

@immutable
class User {
  final String id;
  final Peer peer;

  User(this.id, this.peer);

  void onConversationCreated(Map<String, dynamic> data) {
    peer.sendRequest('onConversationCreated', data);
  }

  void receiveMessage(String conversationId, Map<String, dynamic> data) {
    peer.sendRequest('receiveMessage$conversationId', data);
  }

  void updateMessageState(String conversationId, Map<String, dynamic> data) {
    peer.sendRequest('updateMessageState$conversationId', data);
  }
}
