import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:backend/backend.dart';
import 'package:backend/src/api_v1/projects/models/update_project/update_project.dart';
import 'package:backend/src/api_v1/projects/realtime.dart';
import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/middlewares/check_project_exist.dart';
import 'package:backend/src/rpc/project/parameters.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'project.g.dart';

typedef PeerFactory = Peer Function(WebSocketChannel);
Peer _peerFactory(WebSocketChannel webSocket) => Peer(webSocket.cast<String>());

@immutable
class ProjectService {
  final Rpcs _rpcs;

  final Map<String, Realtime> _realtime = <String, Realtime>{};
  final _logger = Logger('ProjectService');
  final PeerFactory peerFactory;

  ProjectService(this._rpcs, {this.peerFactory = _peerFactory});

  @visibleForTesting
  Map<String, Realtime> get realtime => _realtime;

  Router get router => _$ProjectServiceRouter(this);

  @Route.get('/<id>/ws')
  FutureOr<Response> project(Request request) => Pipeline()
      .addMiddleware(checkProjectExistMiddleware(_rpcs.projectRpcs.getProjectByKey))
      .addHandler((request) => webSocketHandler((WebSocketChannel webSocket) => onWebSocket(request, webSocket))(request))(request);

  @Route('PATCH', '/<projectKey>')
  Future<Response> updateProject(Request request) async {
    final projectKey = params(request, 'projectKey');
    final token = request.headers[HttpHeaders.authorizationHeader];
    if (token == null) {
      return Response(HttpStatus.badRequest);
    }
    final tokenData = await _rpcs.tokenRpcs.getToken.request(token);
    if (tokenData == null) {
      return Response(HttpStatus.unauthorized);
    }
    final accountData = await _rpcs.accountRpcs.getAccountById.request(tokenData.accountId);
    final projectData = await _rpcs.projectRpcs.getProjectByKey.request(projectKey);
    if (projectData.id != accountData.projectId) {
      return Response(HttpStatus.unauthorized);
    }
    final body = (json.decode(await request.readAsString()) as Map).cast<String, dynamic>();
    final updateProjectDataRequest = UpdateProjectDataRequest.fromJson(body);
    final production = projectData.production?.copyWith(webHook: updateProjectDataRequest.productionWebHook ?? projectData.production.webHook);
    final development = projectData.development.copyWith(webHook: updateProjectDataRequest.developmentWebHook ?? projectData.development.webHook);
    final updatedProjectData =
        projectData.copyWith(production: production, development: development, isSecure: updateProjectDataRequest.isSecure ?? projectData.isSecure);
    await _rpcs.projectRpcs.updateProject.request(
        UpdateProjectParameters(projectData.id, updatedProjectData.production?.webHook, updatedProjectData.development.webHook, updatedProjectData.isSecure));
    return Response(HttpStatus.ok);
  }

  Future<void> onWebSocket(Request request, WebSocketChannel webSocket) async {
    final logger = Logger('${_logger.name}.onWebSocket');
    final peer = peerFactory(webSocket);
    final projectData = request.context['projectEnvironment'] as ProjectEnvironment;
    _realtime.putIfAbsent(
      projectData.key,
      () => Realtime(
        projectData.key,
        _rpcs.conversationRpcs.updateConversationSubjectAndAvatar,
        _rpcs.conversationRpcs.getConversationById,
        _rpcs.conversationRpcs.saveConversation,
        _rpcs.conversationRpcs.updateConversationLastUpdate,
        _rpcs.conversationRpcs.getNumberOfMessageForConversation,
        _rpcs.conversationsRpcs.getConversationsForUser,
        _rpcs.messageRpcs.saveMessage,
        _rpcs.messageRpcs.getMessageById,
        _rpcs.messageRpcs.updateMessageState,
        _rpcs.messagesRpcs.getMessagesForConversation,
        _rpcs.projectRpcs.getProjectByKey,
        _rpcs.userRpcs,
      ),
    );
    final realtime = _realtime[projectData.key];
    realtime.addPeer(peer);
    logger.info('Number of connected peers ${realtime.connectedPeers.length}');
    await peer.listen();
    await realtime.removePeer(peer);
    logger.info('Number of connected peers ${realtime.connectedPeers.length}');
    if (realtime.connectedPeers.isEmpty) {
      logger.info('Remove project ${projectData.key}');
      _realtime.remove(projectData.key);
    }
  }
}
