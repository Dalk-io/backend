import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/rpc/rpcs.dart';
import 'package:backend/src/utils/pretty_json.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';
import 'package:mailer/mailer.dart';

part 'paddle.g.dart';

class PaddleService {
  final Rpcs _rpcs;

  final _logger = Logger('PaddleService');

  PaddleService(this._rpcs);

  Router get router => _$PaddleServiceRouter(this);

  @Route.post('/web_hook')
  Future<Response> webHook(Request request) async {
    final logger = Logger('${_logger.name}.web_hook');
    if (request.headers[HttpHeaders.userAgentHeader] != 'Paddle') {
      return Response(HttpStatus.unauthorized);
    }
    final data = await request.readAsString();
    final body = Uri.decodeComponent(data).split('&').map((keyValue) => keyValue.split('=')).toList().asMap().map((_, pair) => MapEntry(pair.first, pair.last));
    if (body['alert_name'] == 'subscription_payment_succeeded') {
      await subscriptionPaymentSucceeded(body);
    } else {
      logger.warning(prettyJson(body));
      await _sendMail(body, moreInfos: 'This event is not supported for now.');
    }
    return Response.ok(null);
  }

  Future<void> subscriptionPaymentSucceeded(Map<String, dynamic> body) async {
    final logger = Logger('${_logger.name}.subscriptionPaymentSucceeded');
    final accountData = await _rpcs.accountRpcs.getAccountByEmail.request(body['email'] as String);
    if (accountData == null) {
      logger.info('account not found');
      await _sendMail(body, moreInfos: 'This email is not linked to an account');
      return;
    }
    final project = await _rpcs.projectRpcs.getProjectById.request(accountData.projectId);
    var subscriptionType = SubscriptionType.none;
    if (body['subscription_id'] == '591710' || body['subscription_id'] == '591438') {
      subscriptionType = SubscriptionType.starter;
    } else if (body['subscription_id'] == '591709' || body['subscription_id'] == '591439') {
      subscriptionType = SubscriptionType.complete;
    }
    if (subscriptionType == SubscriptionType.none) {
      await _rpcs.projectRpcs.updateProject.request(project.copyWith(subscriptionType: subscriptionType, production: null));
      return;
    }
    final uuid = Uuid(options: <String, dynamic>{'grng': UuidUtil.cryptoRNG});
    final productionKeyUuid = uuid.v1(
      options: <String, dynamic>{
        'positionalArgs': [Random.secure().nextInt(20000)]
      },
    );
    final productionKey = 'prod_$productionKeyUuid';
    final productionSecretHash = sha512
        .convert(utf8.encode(uuid.v1(options: <String, dynamic>{
          'positionalArgs': [Random.secure().nextInt(20000)]
        })))
        .toString();
    final productionSecret = 'prod_$productionSecretHash';
    final production = ProjectEnvironmentData(productionKey, productionSecret);
    await _rpcs.projectRpcs.updateProject.request(project.copyWith(subscriptionType: subscriptionType, production: production));
  }

  Future<void> _sendMail(Map<String, dynamic> body, {String moreInfos}) async {
    final logger = Logger('${_logger.name}.sendMail');
    final email = 'dev@dalk.io';
    final password = 'qIjteh-rysgef-2simjo';

    final smtpServer = SmtpServer('smtp.ionos.fr', username: email, password: password, ignoreBadCertificate: true);

    final message = Message()
      ..from = Address(email, 'Dalk dev team')
      ..recipients.add('dev@dalk.io')
      ..subject = 'Paddle event not supported or failing :: ${DateTime.now().toUtc()}'
      ..text = '$moreInfos\n\n\n${prettyJson(body)}';

    try {
      final sendReport = await send(message, smtpServer);
      logger.info('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      logger.warning('Message not sent.');
      for (var p in e.problems) {
        logger.warning('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
}
