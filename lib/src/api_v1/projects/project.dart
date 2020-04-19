import 'dart:async';

import 'package:backend/src/api_v1/projects/realtime.dart';
import 'package:backend/src/rpc/conversation/conversation.dart';
import 'package:backend/src/rpc/conversations/conversations.dart';
import 'package:backend/src/rpc/message/message.dart';
import 'package:backend/src/rpc/messages/messages.dart';
import 'package:backend/src/middlewares/check_project_exist.dart';
import 'package:backend/src/models/project.dart';
import 'package:backend/src/rpc/project/get_project_by_key.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'project.g.dart';

typedef PeerFactory = Peer Function(WebSocketChannel);
Peer _peerFactory(WebSocketChannel websocket) => Peer(websocket.cast<String>());

@immutable
class ProjectService {
  final ConversationRpcs _conversationRpcs;
  final ConversationsRpcs _conversationsRpcs;
  final MessageRpcs _messageRpcs;
  final MessagesRpcs _messagesRpcs;
  final GetProjectByKey _getProjectByKey;

  final Map<String, Realtime> _realtimes = <String, Realtime>{};
  final _logger = Logger('ProjectService');
  final PeerFactory peerFactory;

  ProjectService(this._conversationRpcs, this._conversationsRpcs, this._messageRpcs, this._messagesRpcs, this._getProjectByKey,
      {this.peerFactory = _peerFactory});

  Router get router => _$ProjectServiceRouter(this);

  @visibleForTesting
  Map<String, Realtime> get realtimes => _realtimes;

  @Route.get('/<id>/ws')
  FutureOr<Response> project(Request request) => Pipeline()
      // .addMiddleware(addAuthorizedProjectMiddleware(_authorizedIds))
      .addMiddleware(checkProjectExistMiddleware(_getProjectByKey))
      .addHandler((request) => webSocketHandler((WebSocketChannel websocket) => onWebSocket(request, websocket))(request))(request);

  Future<void> onWebSocket(Request request, WebSocketChannel websocket) async {
    final logger = Logger('${_logger.name}.onWebSocket');
    final peer = peerFactory(websocket);
    final projectInformations = request.context['projectInformations'] as ProjectInformations;
    _realtimes.putIfAbsent(
      projectInformations.key,
      () => Realtime(
        projectInformations,
        _conversationRpcs.updateConversationSubjectAndAvatar,
        _conversationRpcs.getConversationById,
        _conversationRpcs.saveConversation,
        _conversationRpcs.updateConversationLastUpdate,
        _conversationRpcs.getNumberOfMessageForConversation,
        _conversationsRpcs.getConversationsForUser,
        _messageRpcs.saveMessage,
        _messageRpcs.getMessageById,
        _messageRpcs.updateMessageState,
        _messagesRpcs.getMessagesForConversation,
        _getProjectByKey,
      ),
    );
    final realtime = _realtimes[projectInformations.key];
    realtime.addPeer(peer);
    logger.info('Number of connected peers ${realtime.connectedPeers.length}');
    await peer.listen();
    realtime.removePeer(peer);
    logger.info('Number of connected peers ${realtime.connectedPeers.length}');
    if (realtime.connectedPeers.isEmpty) {
      logger.info('Remove project ${projectInformations.key}');
      _realtimes.remove(projectInformations.key);
    }
  }
}
