import 'package:backend/src/rpc/message/get_message_by_id.dart';
import 'package:backend/src/rpc/message/save_message.dart';
import 'package:backend/src/rpc/message/update_message_status.dart';
import 'package:meta/meta.dart';

@immutable
class MessageRpcs {
  final GetMessageById getMessageById;
  final SaveMessage saveMessage;
  final UpdateMessageStatus updateMessageStatus;

  MessageRpcs(this.getMessageById, this.saveMessage, this.updateMessageStatus);
}
