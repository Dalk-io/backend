import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';
part 'parameters.g.dart';

@freezed
abstract class SaveContactParameters with _$SaveContactParameters {
  const factory SaveContactParameters(String fullName, String email, @nullable String phone, String plan) = _SaveContactParameters;

  factory SaveContactParameters.fromJson(Map<String, dynamic> json) => _$SaveContactParametersFromJson(json);
}
