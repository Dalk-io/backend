import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:backend/src/api_v1/projects/project.dart';
import 'package:backend/src/models/project.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'mocks/peer.dart';
import 'mocks/rpc/conversation/conversation.dart';
import 'mocks/rpc/conversations/conversations.dart';
import 'mocks/rpc/message/message.dart';
import 'mocks/rpc/messages/messages.dart';
import 'mocks/rpc/project/get_project_by_key.dart';
import 'mocks/web_socket_channel.dart';

void main() {
  test('project doesn\'t exist', () async {
    final getProjectByKeyMock = GetProjectByKeyMock();
    when(getProjectByKeyMock.request(any)).thenAnswer((_) => null);
    final projectService = ProjectService(null, null, null, null, getProjectByKeyMock);
    final response = await projectService.project(Request('GET', Uri.parse('http://localhost/api/v1/projects/toto/ws'), context: {
      'shelf_router/params': {'id': 'toto'}
    }));
    expect(response.statusCode, HttpStatus.notFound);
    final body = json.decode(await response.readAsString()) as Map<String, dynamic>;
    expect(body.containsKey('message'), isTrue);
    expect(body['message'], 'Project toto not found');
  });

  test('onWebSocket', () async {
    final completer = Completer<void>();
    final projectService = ProjectService(
      ConversationRpcsMock(),
      ConversationsRpcsMock(),
      MessageRpcsMock(),
      MessagesRpcsMock(),
      null,
      peerFactory: (_) {
        final peer = PeerMock();
        when(peer.listen()).thenAnswer((_) => completer.future);
        return peer;
      },
    );
    final request = Request('GET', Uri.parse('http://localhost/api/v1/projects/dalk_prod_test_project/ws'), context: {
      'projectInformations': ProjectInformations('dalk_prod_test_project', 'mysupersecret'),
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
    expect(_loggedMessages.first, 'Number of connected peers 1');
    expect(_loggedMessages[1], 'Number of connected peers 0');
    expect(_loggedMessages.last, 'Remove project dalk_prod_test_project');
    expect(projectService.realtimes.length, 0);
  });
}
