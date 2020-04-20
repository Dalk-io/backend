import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

@freezed
abstract class SaveTokenParameters with _$SaveTokenParameters {
  const factory SaveTokenParameters(String token, int accountId, DateTime created) = _SaveTokenParameters;
}
