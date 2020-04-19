import 'dart:async';

import 'package:backend/src/api_v1/projects/realtime.dart';
import 'package:backend/src/rpc/conversation/conversation.dart';
import 'package:backend/src/rpc/conversations/conversations.dart';
import 'package:backend/src/rpc/message/message.dart';
import 'package:backend/src/rpc/messages/messages.dart';
import 'package:backend/src/middlewares/add_authorized_project.dart';
import 'package:backend/src/middlewares/check_project_exist.dart';
import 'package:backend/src/models/project.dart';
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

  final Map<String, Realtime> _realtimes = <String, Realtime>{};
  final _authorizedIds = <Project>[
    Project('dalk_dev_test_project', 'http://localhost:8081/'),
    Project('dalk_test_hadrien-3901329847239577127515', null),
  ];
  final _logger = Logger('ProjectService');
  final PeerFactory peerFactory;

  ProjectService(this._conversationRpcs, this._conversationsRpcs, this._messageRpcs, this._messagesRpcs, {this.peerFactory = _peerFactory});

  Router get router => _$ProjectServiceRouter(this);

  @visibleForTesting
  Map<String, Realtime> get realtimes => _realtimes;

  @Route.get('/<id>/ws')
  FutureOr<Response> project(Request request) => Pipeline()
      .addMiddleware(addAuthorizedProjectMiddleware(_authorizedIds))
      .addMiddleware(checkProjectExistMiddleware)
      .addHandler((request) => webSocketHandler((WebSocketChannel websocket) => onWebSocket(request, websocket))(request))(request);

  Future<void> onWebSocket(Request request, WebSocketChannel websocket) async {
    final logger = Logger('${_logger.name}.onWebSocket');
    final peer = peerFactory(websocket);
    final project = request.context['project'] as Project;
    _realtimes.putIfAbsent(
      project.id,
      () => Realtime(
        project,
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
      ),
    );
    final realtime = _realtimes[project.id];
    realtime.addPeer(peer);
    logger.info('Number of connected peers ${realtime.connectedPeers.length}');
    await peer.listen();
    realtime.removePeer(peer);
    logger.info('Number of connected peers ${realtime.connectedPeers.length}');
    if (realtime.connectedPeers.isEmpty) {
      logger.info('Remove project ${project.id}');
      _realtimes.remove(project.id);
    }
  }
}
