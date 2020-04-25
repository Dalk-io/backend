import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_project.freezed.dart';
part 'update_project.g.dart';

@freezed
abstract class UpdateProjectDataRequest with _$UpdateProjectDataRequest {
  const factory UpdateProjectDataRequest({String productionWebHook, String developmentWebHook, bool isSecure}) = _UpdateProjectDataRequest;

  factory UpdateProjectDataRequest.fromJson(Map<String, dynamic> json) => _$UpdateProjectDataRequestFromJson(json);
}
