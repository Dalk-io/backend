import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

@freezed
abstract class UpdateProjectParameters with _$UpdateProjectParameters {
  const factory UpdateProjectParameters(int projectId, String productionWebHook, String developmentWebHook, bool productionIsSecure, bool developmentIsSecure) =
      _UpdateProjectParameters;
}
