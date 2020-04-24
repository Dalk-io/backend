import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

enum UserState {
  offline,
  online,
}

@freezed
abstract class SaveUserParameters with _$SaveUserParameters {
  const factory SaveUserParameters(
    String projectId,
    String id,
    @nullable String name,
    @nullable String avatar,
    UserState state,
  ) = _SaveUserParameters;
}

@freezed
abstract class GetUserByIdParameters with _$GetUserByIdParameters {
  const factory GetUserByIdParameters(String projectId, String id) = _GetUserByIdParameters;
}

@freezed
abstract class UpdateUserParameters with _$UpdateUserParameters {
  const factory UpdateUserParameters(
    String projectId,
    String id,
    @nullable String name,
    @nullable String avatar,
    UserState state,
  ) = _UpdateUserParameters;
}
