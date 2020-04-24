import 'package:freezed_annotation/freezed_annotation.dart';

part 'logout.freezed.dart';
part 'logout.g.dart';

@freezed
abstract class LogoutDataRequest with _$LogoutDataRequest {
  const factory LogoutDataRequest(String token) = _LogoutDataRequest;

  factory LogoutDataRequest.fromJson(Map<String, dynamic> json) => _$LogoutDataRequestFromJson(json);
}
