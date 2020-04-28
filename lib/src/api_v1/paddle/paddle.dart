import 'package:backend/src/rpc/rpcs.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

part 'paddle.g.dart';

class PaddleService {
  final Rpcs _rpcs;

  PaddleService(this._rpcs);

  Router get router => _$PaddleServiceRouter(this);

  @Route.post('/web_hook')
  Future<Response> webHook(Request request) async {
    final data = await request.readAsString();
    final body = data.split('&').map((keyValue) => keyValue.split('=')).toList().asMap().map((_, pair) => MapEntry(pair.first, pair.last));
    // if (body['alert_name'] == 'subscription_payment_succeeded') {
    //   await subscriptionPaymentSucceeded(body);
    // } else if (body['alert_name'] == 'subscription_created') {
    //   await subscriptionCreated(body);
    // }
    return Response.ok(null);
  }

  // Future<Response> subscriptionPaymentSucceeded(Map<String, dynamic> body) {
  //   final accountData = _rpcs.accountRpcs.getAccountByEmail.request(body['email'] as String);
  // }

  // Future<Response> subscriptionCreated(Map<String, dynamic> body) {
  //   final accountData = _rpcs.accountRpcs.getAccountByEmail.request(body['email'] as String);
  // }
}
