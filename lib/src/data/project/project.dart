import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
abstract class ProjectEnvironmentData with _$ProjectEnvironmentData {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectEnvironmentData(
    @JsonKey(includeIfNull: false) String key,
    @JsonKey(includeIfNull: false) String secret, {
    @nullable @JsonKey(includeIfNull: false) String webHook,
    @Default(false) bool isSecure,
  }) = _ProjectEnvironmentData;

  factory ProjectEnvironmentData.fromJson(Map<String, dynamic> json) => _$ProjectEnvironmentDataFromJson(json);
}

enum SubscriptionType {
  starter,
  complete,
  none,
}

@freezed
abstract class ProjectsData with _$ProjectsData {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectsData(
    ProjectEnvironmentData development, {
    @Default(SubscriptionType.none) SubscriptionType subscriptionType,
    @nullable @JsonKey(includeIfNull: false) int id,
    @nullable @JsonKey(includeIfNull: false) ProjectEnvironmentData production,
    @Default(5) int groupLimitation,
  }) = _ProjectsData;

  factory ProjectsData.fromJson(Map<String, dynamic> json) => _$ProjectsDataFromJson(json);
}
