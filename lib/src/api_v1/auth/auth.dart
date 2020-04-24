import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:backend/backend.dart';
import 'package:backend/src/api_v1/auth/models/is_logged/is_logged.dart';
import 'package:backend/src/api_v1/auth/models/login/login.dart';
import 'package:backend/src/api_v1/auth/models/register/register.dart';
import 'package:backend/src/data/account/account.dart';
import 'package:backend/src/data/project/project.dart';
import 'package:backend/src/rpc/account/parameters.dart';
import 'package:backend/src/rpc/token/parameters.dart';
import 'package:backend/src/utils/check_request_parameters.dart';
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
    final checkParametersResponse = checkRequestParameters(['email', 'password'], body);
    if (checkParametersResponse != null) {
      return checkParametersResponse;
    }
    final encryptedPassword = sha512.convert(utf8.encode(body['password'])).toString();
    final account = await _accountRpcs.getAccountByEmailAndPassword.request(GetAccountByEmailAndPasswordParameters(body['email'], encryptedPassword));
    if (account == null) {
      return Response.notFound('');
    }
    final token = _generateToken();
    await _tokenRpcs.saveToken.request(SaveTokenParameters(token, account.id, DateTime.now().toUtc()));
    final project = await _projectRpcs.getProjectById.request(account.projectId);
    final response = LoginDataResponse(token, account.copyWith(projectId: null, password: null), project);
    return Response(
      HttpStatus.ok,
      body: json.encode(response.toJson()),
    );
  }

  @Route.get('/is_logged')
  Future<Response> isLogged(Request request) async {
    final token = request.headers[HttpHeaders.authorizationHeader];
    if (token == null) {
      return Response(HttpStatus.badRequest);
    }
    final tokenData = await _tokenRpcs.getToken.request(token);
    if (tokenData == null) {
      return Response(HttpStatus.unauthorized);
    }
    final accountData = await _accountRpcs.getAccountById.request(tokenData.accountId);
    final projectsData = await _projectRpcs.getProjectById.request(accountData.projectId);
    final response = IsLoggedDataResponse(tokenData.token, accountData.copyWith(password: null, projectId: null), projectsData);
    return Response(
      HttpStatus.ok,
      body: json.encode(response.toJson()),
    );
  }

  @Route.post('/logout')
  Future<Response> logout(Request request) async {
    final token = request.headers[HttpHeaders.authorizationHeader];
    if (token == null) {
      return Response(HttpStatus.badRequest);
    }
    await _tokenRpcs.deleteToken.request(token);
    return Response(HttpStatus.ok);
  }

  @Route.post('/register')
  Future<Response> register(Request request) async {
    final body = (json.decode(await request.readAsString()) as Map).cast<String, String>();
    final checkParametersResponse = checkRequestParameters(['lastName', 'firstName', 'email', 'password', 'subscriptionType'], body);
    if (checkParametersResponse != null) {
      return checkParametersResponse;
    }
    if (!['starter', 'complete'].contains(body['subscriptionType'])) {
      return Response(
        HttpStatus.badRequest,
        body: json.encode({
          'message': 'Bad required parameters',
          'data': 'Supported value are [starter|complete]',
        }),
      );
    }
    final registerData = RegisterDataRequest.fromJson(body);
    final password = registerData.password;
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
    final firstName = registerData.firstName;
    final lastName = registerData.lastName;
    final email = registerData.email;
    final account = await _accountRpcs.getAccountByEmail.request(email);
    if (account != null) {
      return Response(HttpStatus.conflict, body: json.encode({'message': 'Account already exist', 'data': email}));
    }
    final token = _generateToken();
    final uuid = Uuid(options: <String, dynamic>{'grng': UuidUtil.cryptoRNG});
    final developmentKeyUuid = uuid.v1(
      options: <String, dynamic>{
        'positionalArgs': [Random.secure().nextInt(20000)]
      },
    );
    final developmentKey = 'dev_$developmentKeyUuid';
    final developmentSecretHash = sha512
        .convert(utf8.encode(uuid.v1(options: <String, dynamic>{
          'positionalArgs': [Random.secure().nextInt(20000)]
        })))
        .toString();
    final developmentSecret = 'dev_$developmentSecretHash';
    final project = ProjectsData(ProjectEnvironment(developmentKey, developmentSecret), SubscriptionType.starter);
    final projectId = await _projectRpcs.saveProject.request(project);
    final accountId = await _accountRpcs.saveAccount.request(SaveAccountParameters(firstName, lastName, email, encryptedPassword, projectId));
    await _tokenRpcs.saveToken.request(SaveTokenParameters(token, accountId, DateTime.now().toUtc()));
    final response = RegisterDataResponse(token, AccountData(id: accountId, firstName: firstName, lastName: lastName, email: email), project);
    return Response(
      HttpStatus.created,
      body: json.encode(response.toJson()),
    );
  }

  String _generateToken() {
    final uuid = Uuid(options: <String, dynamic>{'grng': UuidUtil.cryptoRNG});
    final id = uuid.v4(options: <String, dynamic>{
      'positionalArgs': [Random().nextInt(2000)],
    });
    final token = sha512.convert(utf8.encode(id)).toString();
    return token;
  }
}
