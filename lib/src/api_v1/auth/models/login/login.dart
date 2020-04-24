import 'package:backend/src/data/account/account.dart';
import 'package:backend/src/data/project/project.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login.freezed.dart';
part 'login.g.dart';

@freezed
abstract class LoginDataResponse with _$LoginDataResponse {
  @JsonSerializable(explicitToJson: true)
  const factory LoginDataResponse(String token, AccountData user, ProjectsData project) = _LoginDataResponse;

  factory LoginDataResponse.fromJson(Map<String, dynamic> json) => _$LoginDataResponseFromJson(json);
}
