import 'package:backend/src/data/account/account.dart';
import 'package:backend/src/data/project/project.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'register.freezed.dart';
part 'register.g.dart';

@freezed
abstract class RegisterDataRequest with _$RegisterDataRequest {
  const factory RegisterDataRequest(String firstName, String lastName, String email, String password, SubscriptionType subscriptionType) = _RegisterDataRequest;

  factory RegisterDataRequest.fromJson(Map<String, dynamic> json) => _$RegisterDataRequestFromJson(json);
}

@freezed
abstract class RegisterDataResponse with _$RegisterDataResponse {
  @JsonSerializable(explicitToJson: true)
  const factory RegisterDataResponse(String token, AccountData user, ProjectsData project) = _RegisterDataResponse;

  factory RegisterDataResponse.fromJson(Map<String, dynamic> json) => _$RegisterDataResponseFromJson(json);
}
