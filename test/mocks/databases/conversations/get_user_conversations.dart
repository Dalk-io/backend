import 'package:backend/src/databases/conversations/get_conversations_for_user.dart';
import 'package:backend/src/databases/message/get_last_message_for_conversation.dart';
import 'package:mockito/mockito.dart';

//  ignore: must_be_immutable
class GetConversationsForUserFromDatabaseMock extends Mock implements GetConversationsForUserFromDatabase {}

//  ignore: must_be_immutable
class GetLastMessageForConversationFromDatabaseMock extends Mock implements GetLastMessageForConversationFromDatabase {}
