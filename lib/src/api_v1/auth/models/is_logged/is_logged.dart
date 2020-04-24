import 'package:backend/src/data/account/account.dart';
import 'package:backend/src/data/project/project.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'is_logged.freezed.dart';
part 'is_logged.g.dart';

@freezed
abstract class IsLoggedDataRequest with _$IsLoggedDataRequest {
  const factory IsLoggedDataRequest(String token) = _IsLoggedDataRequest;

  factory IsLoggedDataRequest.fromJson(Map<String, dynamic> json) => _$IsLoggedDataRequestFromJson(json);
}

@freezed
abstract class IsLoggedDataResponse with _$IsLoggedDataResponse {
  @JsonSerializable(explicitToJson: true)
  const factory IsLoggedDataResponse(String token, AccountData user, ProjectsData project) = _IsLoggedDataResponse;

  factory IsLoggedDataResponse.fromJson(Map<String, dynamic> json) => _$IsLoggedDataResponseFromJson(json);
}
