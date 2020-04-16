import 'package:backend/src/rpc/message/get_message_by_id.dart';
import 'package:backend/src/rpc/message/save_message.dart';
import 'package:backend/src/rpc/message/update_message_state.dart';
import 'package:meta/meta.dart';

@immutable
class MessageRpcs {
  final GetMessageById getMessageById;
  final SaveMessage saveMessage;
  final UpdateMessageState updateMessageState;

  MessageRpcs(this.getMessageById, this.saveMessage, this.updateMessageState);
}
