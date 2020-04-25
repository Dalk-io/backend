import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
abstract class ProjectEnvironment with _$ProjectEnvironment {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectEnvironment(
    @JsonKey(includeIfNull: false) String key,
    @JsonKey(includeIfNull: false) String secret, {
    @nullable @JsonKey(includeIfNull: false) String webHook,
    @Default(false) bool isSecure,
  }) = _ProjectEnvironment;

  factory ProjectEnvironment.fromJson(Map<String, dynamic> json) => _$ProjectEnvironmentFromJson(json);
}

enum SubscriptionType {
  starter,
  complete,
}

@freezed
abstract class ProjectsData with _$ProjectsData {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectsData(
    ProjectEnvironment development,
    SubscriptionType subscriptionType, {
    @nullable @JsonKey(includeIfNull: false) int id,
    @nullable @JsonKey(includeIfNull: false) ProjectEnvironment production,
    @Default(5) int groupLimitation,
  }) = _ProjectsData;

  factory ProjectsData.fromJson(Map<String, dynamic> json) => _$ProjectsDataFromJson(json);
}
