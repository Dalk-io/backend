import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:backend/src/api_v1/projects/project.dart';
import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/rpc/project/project.dart';
import 'package:backend/src/rpc/rpcs.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'src/mocks/peer.dart';
import 'src/mocks/rpc/conversation/conversation.dart';
import 'src/mocks/rpc/conversations/conversations.dart';
import 'src/mocks/rpc/message/message.dart';
import 'src/mocks/rpc/messages/messages.dart';
import 'src/mocks/rpc/project/get_project_by_key.dart';
import 'src/mocks/rpc/user/user.dart';
import 'src/mocks/web_socket_channel.dart';

void main() {
  test('project doesn\'t exist', () async {
    final getProjectByKeyMock = GetProjectByKeyMock();
    when(getProjectByKeyMock.request(any)).thenAnswer((_) => null);
    final rpcs = Rpcs(null, null, null, null, null, ProjectRpcs(getProjectByKeyMock, null, null, null), null, null, null);
    final projectService = ProjectService(rpcs);
    final response = await projectService.project(Request('GET', Uri.parse('http://localhost/api/v1/projects/toto/ws'), context: {
      'shelf_router/params': {'projectKey': 'toto'}
    }));
    expect(response.statusCode, HttpStatus.notFound);
    final body = json.decode(await response.readAsString()) as Map<String, dynamic>;
    expect(body.containsKey('message'), isTrue);
    expect(body['message'], 'Project toto not found');
  });

  test('onWebSocket', () async {
    final completer = Completer<void>();
    final getProjectByKeyMock = GetProjectByKeyMock();
    final rpcs = Rpcs(
      MessageRpcsMock(),
      MessagesRpcsMock(),
      ConversationRpcsMock(),
      ConversationsRpcsMock(),
      null,
      ProjectRpcs(getProjectByKeyMock, null, null, null),
      null,
      null,
      UserRpcsMock(),
    );

    final projectService = ProjectService(rpcs, peerFactory: (_) {
      final peer = PeerMock();
      when(peer.listen()).thenAnswer((_) => completer.future);
      return peer;
    });
    final request = Request('GET', Uri.parse('http://localhost/api/v1/projects/fake_project_id/ws'), context: {
      'projectEnvironment': ProjectEnvironmentData('fake_project_id', 'mySuperSecret'),
    });
    final webSocket = WebSocketChannelMock();
    final _loggedMessages = <String>[];
    await runZoned(() async {
      Logger.root.onRecord.where((record) => record.loggerName == 'ProjectService.onWebSocket').map((record) => record.message).listen(print);
      final onWebSocketFuture = projectService.onWebSocket(request, webSocket);
      completer.complete();
      await onWebSocketFuture;
    }, zoneSpecification: ZoneSpecification(print: (_, __, ___, message) {
      _loggedMessages.add(message);
    }));
    expect(_loggedMessages.length, 3);
    expect(_loggedMessages.elementAt(0), 'Number of connected peers 1');
    expect(_loggedMessages.elementAt(1), 'Number of connected peers 0');
    expect(_loggedMessages.last, 'Remove project fake_project_id');
    expect(projectService.realtime.length, 0);
  });
}
