import 'package:freezed_annotation/freezed_annotation.dart';

part 'parameters.freezed.dart';

@freezed
abstract class SaveAccountParameters with _$SaveAccountParameters {
  const factory SaveAccountParameters(String firstName, String lastName, String email, String password, int projectId) = _SaveAccountParameters;
}

@freezed
abstract class GetAccountByEmailAndPasswordParameters with _$GetAccountByEmailAndPasswordParameters {
  const factory GetAccountByEmailAndPasswordParameters(String email, String password) = _GetAccountByEmailAndPasswordParameters;
}
