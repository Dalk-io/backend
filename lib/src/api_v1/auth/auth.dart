import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:backend/backend.dart';
import 'package:backend/src/models/project.dart';
import 'package:backend/src/rpc/account/parameters.dart';
import 'package:backend/src/rpc/token/parameters.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';

part 'auth.g.dart';

@immutable
class AuthService {
  final AccountRpcs _accountRpcs;
  final ProjectRpcs _projectRpcs;
  final TokenRpcs _tokenRpcs;

  AuthService(this._accountRpcs, this._projectRpcs, this._tokenRpcs);

  Router get router => _$AuthServiceRouter(this);

  @Route.post('/login')
  Future<Response> login(Request request) async {
    final body = (json.decode(await request.readAsString()) as Map).cast<String, String>();
    final missingParameters = <String>[];
    if (!body.keys.contains('email')) {
      missingParameters.add('email');
    }
    if (!body.keys.contains('password')) {
      missingParameters.add('password');
    }
    if (missingParameters.isNotEmpty) {
      return Response(
        HttpStatus.badRequest,
        body: json.encode({
          'message': 'Missing required parameters',
          'data': missingParameters,
        }),
      );
    }
    // await _login(body['email'], body['password']);
    return Response(HttpStatus.notImplemented, body: 'not implemented');
  }

  @Route.post('/logout')
  Future<Response> logout(Request request) async {
    return Response(HttpStatus.notImplemented, body: 'not implemented');
  }

  @Route.post('/register')
  Future<Response> register(Request request) async {
    final body = (json.decode(await request.readAsString()) as Map).cast<String, String>();
    final missingParameters = <String>[];
    if (!body.keys.contains('lastName')) {
      missingParameters.add('lastName');
    }
    if (!body.keys.contains('firstName')) {
      missingParameters.add('firstName');
    }
    if (!body.keys.contains('email')) {
      missingParameters.add('email');
    }
    if (!body.keys.contains('password')) {
      missingParameters.add('password');
    }
    if (missingParameters.isNotEmpty) {
      return Response(
        HttpStatus.badRequest,
        body: json.encode({
          'message': 'Missing required parameters',
          'data': missingParameters,
        }),
      );
    }
    final password = body['password'];
    if (password.length < 8) {
      return Response(
        HttpStatus.badRequest,
        body: json.encode({
          'message': 'Password is too short',
          'data': password.length,
        }),
      );
    }
    final encryptedPassword = sha512.convert(utf8.encode(password)).toString();
    final firstName = body['firstName'];
    final lastName = body['lastName'];
    final email = body['email'];
    final account = await _accountRpcs.getAccountByEmail.request(email);
    if (account != null) {
      return Response(HttpStatus.conflict, body: json.encode({'message': 'Account already exist', 'data': email}));
    }
    final token = await _login(email, password);
    final uuid = Uuid(options: <String, dynamic>{'grng': UuidUtil.cryptoRNG});
    final developmentKeyUuid = uuid.v1(
      options: <String, dynamic>{
        'positionalArgs': [Random.secure().nextInt(20000)]
      },
    );
    final developmentKey = 'dev_$developmentKeyUuid';
    final developmentSecretHash = sha512
        .convert(utf8.encode(uuid.v1(
          options: <String, dynamic>{
            'positionalArgs': [Random.secure().nextInt(20000)]
          },
        )))
        .toString();
    final developmentSecret = 'dev_$developmentSecretHash';
    final project = Project(development: ProjectInformations(developmentKey, developmentSecret, groupLimitation: 5));
    final projectId = await _projectRpcs.saveProject.request(project);
    final accountId = await _accountRpcs.saveAccount.request(SaveAccountParameters(firstName, lastName, email, encryptedPassword, projectId));
    await _tokenRpcs.saveToken.request(SaveTokenParameters(token, accountId, DateTime.now().toUtc()));
    return Response(
      HttpStatus.created,
      body: json.encode(
        {
          'token': token,
          'user': {
            'email': email,
            'developmentKey': developmentKey,
            'developmentSecret': developmentSecret,
          }
        },
      ),
    );
  }

  Future<String> _login(String email, String password) async {
    final uuid = Uuid(options: <String, dynamic>{'grng': UuidUtil.cryptoRNG});
    final id = uuid.v1(options: <String, dynamic>{
      'positionalArgs': [Random().nextInt(2000)],
    });
    final token = sha512.convert(utf8.encode(id)).toString();
    return token;
  }
}
