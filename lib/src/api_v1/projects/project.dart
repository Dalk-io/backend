import 'dart:async';
import 'dart:io';

import 'package:backend/backend.dart';
import 'package:backend/src/api_v1/projects/realtime.dart';
import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/middlewares/check_project_exist.dart';
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

  @Route.post('/<projectId>')
  Future<Response> updateProject(Request request) async {
    return Response(HttpStatus.notImplemented);
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
