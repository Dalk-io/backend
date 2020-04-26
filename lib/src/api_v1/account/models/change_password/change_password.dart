import 'package:freezed_annotation/freezed_annotation.dart';

part 'change_password.freezed.dart';
part 'change_password.g.dart';

@freezed
abstract class ChangePasswordDataRequest with _$ChangePasswordDataRequest {
  const factory ChangePasswordDataRequest(String password) = _ChangePasswordDataRequest;

  factory ChangePasswordDataRequest.fromJson(Map<String, dynamic> json) => _$ChangePasswordDataRequestFromJson(json);
}
