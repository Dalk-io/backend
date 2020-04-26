import 'package:backend/src/api_v1/projects/realtime.dart';
import 'package:backend/src/data/conversation/conversation.dart';
import 'package:backend/src/data/message/message.dart';
import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/data/user/user.dart';
import 'package:backend/src/rpc/conversation/parameters.dart';
import 'package:backend/src/rpc/conversations/parameters.dart';
import 'package:backend/src/rpc/message/parameters.dart';
import 'package:backend/src/rpc/messages/parameters.dart';
import 'package:backend/src/rpc/user/parameters.dart';
import 'package:backend/src/rpc/user/user.dart';
import 'package:mockito/mockito.dart';

import 'mocks/io_client.dart';
import 'mocks/rpc/conversation/get_conversation_by_id.dart';
import 'mocks/rpc/conversation/get_number_of_message_for_conversation.dart';
import 'mocks/rpc/conversation/save_conversation.dart';
import 'mocks/rpc/conversation/update_conversation_last_update.dart';
import 'mocks/rpc/conversation/update_conversation_subject_and_avatar.dart';
import 'mocks/rpc/conversations/get_conversations_for_user.dart';
import 'mocks/rpc/message/get_message_by_id.dart';
import 'mocks/rpc/message/save_message.dart';
import 'mocks/rpc/message/update_message_state.dart';
import 'mocks/rpc/messages/get_messages_for_conversation.dart';
import 'mocks/rpc/project/get_project_by_key.dart';
import 'mocks/rpc/user/get_user_by_id.dart';
import 'mocks/rpc/user/save_user.dart';
import 'mocks/rpc/user/update_user.dart';

@deprecated
Realtime initRealtime(String projectKey, {bool withWebHook = false}) {
  //  rpcs
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

  //  mock rpc
  final testProjectId = projectKey;
  final testProjectSecret = 'secret';

  when(getUserById.request(GetUserByIdParameters(testProjectId, '1'))).thenAnswer((_) async => UserData('1'));
  when(getUserById.request(GetUserByIdParameters(testProjectId, '2'))).thenAnswer((_) async => UserData('2'));
  when(getUserById.request(GetUserByIdParameters(testProjectId, '10'))).thenAnswer((_) async => UserData('10'));

  when(getProjectByKey.request(testProjectId)).thenAnswer(
      (_) async => ProjectsData(ProjectEnvironmentData(testProjectId, testProjectSecret, webHook: withWebHook ? 'tet' : null), SubscriptionType.starter));

  when(getConversationsForUser.request(GetConversationsForUserParameters(testProjectId, '1'))).thenAnswer((_) async => <ConversationData>[
        ConversationData(id: '1', admins: [UserData('1')], users: [UserData('1'), UserData('2')]),
      ]);
  when(getConversationsForUser.request(GetConversationsForUserParameters(testProjectId, '12'))).thenAnswer((_) async => <ConversationData>[
        ConversationData(id: '12', admins: [UserData('1')], users: [UserData('1'), UserData('2')]),
      ]);
  when(getConversationsForUser.request(GetConversationsForUserParameters(testProjectId, '10'))).thenAnswer((_) async => <ConversationData>[]);

  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '6')))
      .thenAnswer((_) async => ConversationData(id: '6', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '7'))).thenAnswer((_) async => ConversationData(id: '7', admins: [
        UserData('1')
      ], users: [
        UserData('1'),
        UserData('2')
      ], messages: [
        MessageData(
          '1',
          testProjectId,
          '6',
          '1',
          'Hello world',
          DateTime.utc(2020, 01, 01, 14, 30),
          [
            MessageStatusByUserData('1', MessageStatus.seen),
            MessageStatusByUserData('2', MessageStatus.seen),
          ],
        ),
      ]));
  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '1')))
      .thenAnswer((_) async => ConversationData(id: '1', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '12'))).thenAnswer((_) async => ConversationData(
      id: '12',
      admins: [UserData('1')],
      users: [UserData('1'), UserData('2')],
      messages: [MessageData('1', testProjectId, '6', '1', 'Hello world', DateTime(2020, 01, 01, 14, 30), [])]));
  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '12')))
      .thenAnswer((_) async => ConversationData(id: '12', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '13')))
      .thenAnswer((_) async => ConversationData(id: '13', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '14')))
      .thenAnswer((_) async => ConversationData(id: '14', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '15')))
      .thenAnswer((_) async => ConversationData(id: '15', admins: [UserData('1')], users: [UserData('1'), UserData('2'), UserData('3')]));
  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '17')))
      .thenAnswer((_) async => ConversationData(id: '17', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '2')))
      .thenAnswer((_) async => ConversationData(id: '23', subject: 'Test', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));
  when(getConversationById.request(GetConversationByIdParameters(testProjectId, '3')))
      .thenAnswer((_) async => ConversationData(id: '34', avatar: 'Test', admins: [UserData('1')], users: [UserData('1'), UserData('2')]));

  when(updateConversationSubjectAndAvatar.request(UpdateConversationSubjectAndAvatarParameters(testProjectId, '12', subject: 'Test')))
      .thenAnswer((_) async => null);

  when(getMessagesForConversation.request(GetMessagesForConversationParameters(testProjectId, '6'))).thenAnswer((_) async => <MessageData>[
        MessageData('2', testProjectId, '6', '1', 'How are you?', DateTime(2020, 01, 01, 14, 30), []),
        MessageData('1', testProjectId, '6', '1', 'Hello world', DateTime(2020, 01, 01, 14, 30), []),
      ]);
  when(getMessagesForConversation.request(GetMessagesForConversationParameters(testProjectId, '6', from: 0, to: -1))).thenAnswer((_) async => <MessageData>[
        MessageData('2', testProjectId, '6', '1', 'How are you?', DateTime(2020, 01, 01, 14, 30), []),
        MessageData('1', testProjectId, '6', '1', 'Hello world', DateTime(2020, 01, 01, 14, 30), []),
      ]);

  when(getMessagesForConversation.request(GetMessagesForConversationParameters(testProjectId, '6', from: 0, to: 1))).thenAnswer((_) async => <MessageData>[
        MessageData('2', testProjectId, '6', '1', 'How are you?', DateTime(2020, 01, 01, 14, 30), []),
        MessageData('1', testProjectId, '6', '1', 'Hello world', DateTime(2020, 01, 01, 14, 30), []),
      ]);

  when(getMessagesForConversation.request(GetMessagesForConversationParameters(testProjectId, '12', from: 0, to: 1))).thenAnswer((_) async => <MessageData>[
        MessageData('1', testProjectId, '12', '1', 'Hello world', DateTime(2020, 01, 01, 14, 30), []),
      ]);

  when(getNumberOfMessageForConversation.request(GetNumberOfMessageForConversationParameter(testProjectId, '13'))).thenAnswer((_) async => 0);
  when(getNumberOfMessageForConversation.request(GetNumberOfMessageForConversationParameter(testProjectId, '14'))).thenAnswer((_) async => 14);
  when(getNumberOfMessageForConversation.request(GetNumberOfMessageForConversationParameter(testProjectId, '15'))).thenAnswer((_) async => 0);
  when(getNumberOfMessageForConversation.request(GetNumberOfMessageForConversationParameter(testProjectId, '16'))).thenAnswer((_) async => 0);

  // when(saveMessage.request(SaveMessageParameters(
  //         '1', testProjectId, '13', '1', 'Hello world', [MessageStateByUserData('1', MessageState.seen), MessageStateByUserData('2', MessageState.sent)])))
  //     .thenAnswer((_) async => 1);
  // when(saveMessage.request(SaveMessageParameters(
  //         '1', testProjectId, '14', '1', 'Hello world', [MessageStateByUserData('1', MessageState.seen), MessageStateByUserData('2', MessageState.sent)])))
  //     .thenAnswer((_) async => 15);
  // when(saveMessage.request(SaveMessageParameters('1', testProjectId, '15', '1', 'Hello world', [
  //   MessageStateByUserData('1', MessageState.seen),
  //   MessageStateByUserData('2', MessageState.sent),
  //   MessageStateByUserData('3', MessageState.sent)
  // ]))).thenAnswer((_) async => 1);
  // when(saveMessage.request(SaveMessageParameters(
  //         '1', testProjectId, '16', '1', 'Hello world', [MessageStateByUserData('1', MessageState.seen), MessageStateByUserData('2', MessageState.sent)])))
  //     .thenAnswer((_) async => 1);

  when(getMessageById.request(GetMessageByIdParameters(testProjectId, '1'))).thenAnswer((_) async => MessageData('1', testProjectId, '1', '1', 'Hello world',
      DateTime.utc(2020, 01, 01, 14, 30), [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.sent)]));

  when(getMessageById.request(GetMessageByIdParameters(testProjectId, '2'))).thenAnswer(
    (_) async => MessageData(
      '2',
      testProjectId,
      '17',
      '1',
      'Hello world',
      DateTime.utc(2020, 01, 01, 14, 30),
      [
        MessageStatusByUserData('1', MessageStatus.seen),
        MessageStatusByUserData('2', MessageStatus.sent),
      ],
    ),
  );
  when(updateMessageStatus.request(UpdateMessageStatusParameters(
      testProjectId, '17', '2', [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.seen)]))).thenAnswer(
    (_) async => MessageData(
      '2',
      testProjectId,
      '17',
      '1',
      'Hello world',
      DateTime.utc(2020, 01, 01, 14, 30),
      [
        MessageStatusByUserData('1', MessageStatus.seen),
        MessageStatusByUserData('2', MessageStatus.seen),
      ],
    ),
  );

  when(getMessageById.request(GetMessageByIdParameters(testProjectId, '3'))).thenAnswer((_) async => MessageData('3', testProjectId, '17', '1', 'Hello world',
      DateTime.utc(2020, 01, 01, 14, 30), [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.seen)]));
  when(updateMessageStatus.request(UpdateMessageStatusParameters(
          testProjectId, '17', '3', [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.seen)])))
      .thenAnswer((_) async => MessageData('3', testProjectId, '17', '1', 'Hello world', DateTime.utc(2020, 01, 01, 14, 30),
          [MessageStatusByUserData('1', MessageStatus.seen), MessageStatusByUserData('2', MessageStatus.seen)]));

  return Realtime(
    testProjectId,
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
    dateTimeFactory: () => DateTime.utc(2020, 01, 01, 14, 30),
    httpClient: IOClientMock(),
    messageIdFactory: () => '1',
  );
}
