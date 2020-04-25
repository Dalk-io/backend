import 'package:backend/src/data/message/message.dart';

Map<String, dynamic> messageToJson(MessageData message, {bool filter = true}) {
  return <String, dynamic>{
    ...message.toJson(),
    'status': computeMessageStatus(message, filter: filter),
    if (filter) 'statusDetails': computeMessageStatusDetails(message),
  }
    ..remove('projectId')
    ..remove('conversationId');
}
