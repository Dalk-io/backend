import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

@freezed
abstract class GetConversationsForUserParameters with _$GetConversationsForUserParameters {
  const factory GetConversationsForUserParameters(String projectId, String userId) = _GetConversationsForUserParameters;
}

@freezed
abstract class GetConversationsForProjectParamters with _$GetConversationsForProjectParamters {
  const factory GetConversationsForProjectParamters(String projectKey, {String from, @Default(1) int take}) = _GetConversationsForProjectParamters;
}
