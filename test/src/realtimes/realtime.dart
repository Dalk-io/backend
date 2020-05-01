import 'dart:math';

import 'package:backend/src/api_v1/projects/realtime.dart';
import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/rpc/user/user.dart';
import 'package:mockito/mockito.dart';

import '../mocks/io_client.dart';
import '../mocks/rpc/conversation/get_conversation_by_id.dart';
import '../mocks/rpc/conversation/get_number_of_message_for_conversation.dart';
import '../mocks/rpc/conversation/save_conversation.dart';
import '../mocks/rpc/conversation/update_conversation_last_update.dart';
import '../mocks/rpc/conversation/update_conversation_subject_and_avatar.dart';
import '../mocks/rpc/conversations/get_conversations_for_user.dart';
import '../mocks/rpc/message/get_message_by_id.dart';
import '../mocks/rpc/message/save_message.dart';
import '../mocks/rpc/message/update_message.dart';
import '../mocks/rpc/message/update_message_state.dart';
import '../mocks/rpc/messages/get_messages_for_conversation.dart';
import '../mocks/rpc/project/get_project_by_key.dart';
import '../mocks/rpc/user/get_user_by_id.dart';
import '../mocks/rpc/user/save_user.dart';
import '../mocks/rpc/user/update_user.dart';

Realtime initRealtime(ProjectsData projectsData) {
  final getUserById = GetUserByIdMock();
  final saveUser = SaveUserMock();
  final updateUserById = UpdateUserByIdMock();
  final userRpcs = UserRpcs(saveUser, getUserById, updateUserById);
  final updateConversationSubjectAndAvatar = UpdateConversationSubjectAndAvatarParametersMock();
  final getConversationById = GetConversationByIdMock();
  final saveConversation = SaveConversationMock();
  final updateConversationLastUpdate = UpdateConversationLastUpdateMock();
  final getNumberOfMessageForConversation = GetNumberOfMessageForConversationMock();
  final getConversationsForUser = GetConversationsForUserMock();
  final saveMessage = SaveMessageMock();
  final getMessageById = GetMessageByIdMock();
  final updateMessageStatus = UpdateMessageStatusMock();
  final getMessagesForConversation = GetMessagesForConversationMock();
  final getProjectByKey = GetProjectByKeyMock();
  final updateMessage = UpdateMessageMock();

  final key = projectsData.production?.key ?? projectsData.development.key;

  when(getProjectByKey.request(key)).thenAnswer((_) async => projectsData);

  final randomMock = Random(1);

  return Realtime(
    key,
    updateConversationSubjectAndAvatar,
    getConversationById,
    saveConversation,
    updateConversationLastUpdate,
    getNumberOfMessageForConversation,
    getConversationsForUser,
    saveMessage,
    getMessageById,
    updateMessageStatus,
    getMessagesForConversation,
    getProjectByKey,
    userRpcs,
    updateMessage,
    dateTimeFactory: () => DateTime.utc(2020, 01, 01, 14, 30),
    httpClient: IOClientMock(),
    messageIdFactory: () => '${randomMock.nextInt(100)}',
  );
}
