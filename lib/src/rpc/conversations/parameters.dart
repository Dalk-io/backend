import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

@freezed
abstract class GetConversationsForUserParameters with _$GetConversationsForUserParameters {
  const factory GetConversationsForUserParameters(String projectId, String userId) = _GetConversationsForUserParameters;
}
