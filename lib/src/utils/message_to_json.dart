import 'package:backend/src/data/message/message.dart';

Map<String, dynamic> messageToJson(MessageData message, {bool filter = true}) {
  final cleanedMessage = message.copyWith(projectId: null, conversationId: null);
  return <String, dynamic>{
    ...cleanedMessage.toJson(),
    'status': computeMessageStatus(message, filter: filter),
    if (filter) 'statusDetails': computeMessageStatusDetails(message),
  };
}
