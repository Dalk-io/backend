import 'dart:convert';
import 'dart:io';

import 'package:backend/src/api_v1/projects/project.dart';
import 'package:backend/src/rpc/contact/parameters.dart';
import 'package:backend/src/rpc/contact/save_contact.dart';
import 'package:backend/src/rpc/conversation/conversation.dart';
import 'package:backend/src/rpc/conversations/conversations.dart';
import 'package:backend/src/rpc/message/message.dart';
import 'package:backend/src/rpc/messages/messages.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'api.g.dart';

@immutable
class ApiV1 {
  final ConversationRpcs _conversationRpcs;
  final ConversationsRpcs _conversationsRpcs;
  final MessageRpcs _messageRpcs;
  final MessagesRpcs _messagesRpcs;

  final SaveContact _saveContact;

  final _logger = Logger('ApiV1');

  ApiV1(this._conversationRpcs, this._conversationsRpcs, this._messageRpcs, this._messagesRpcs, this._saveContact);

  @Route.mount('/projects/')
  Router get _projectService => ProjectService(_conversationRpcs, _conversationsRpcs, _messageRpcs, _messagesRpcs).router;

  Router get router => _$ApiV1Router(this);

  @Route.post('/contact')
  Future<Response> contact(Request request) async {
    final sw = Stopwatch()..start();
    final logger = Logger('${_logger.name}.contact');
    final body = await request.readAsString();
    logger.finest('contact body $body');
    final parameters = SaveContactParameters.fromJson(json.decode(body) as Map<String, dynamic>);
    await _saveContact.request(parameters);
    logger.info('saving contact took ${sw.elapsed}');
    return Response(HttpStatus.created);
  }
}
