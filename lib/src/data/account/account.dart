import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

part 'account.g.dart';

@freezed
abstract class AccountData with _$AccountData {
  const factory AccountData({
    @nullable @JsonKey(includeIfNull: false) int id,
    @required String firstName,
    @required String lastName,
    @required String email,
    @nullable @JsonKey(includeIfNull: false) String password,
    @nullable @JsonKey(includeIfNull: false) int projectId,
  }) = _AccountData;

  factory AccountData.fromJson(Map<String, dynamic> json) => _$AccountDataFromJson(json);

  factory AccountData.fromDatabase(List<dynamic> data) {
    return AccountData(
      id: data[0] as int,
      firstName: data[1] as String,
      lastName: data[2] as String,
      email: data[3] as String,
      password: data[4] as String,
      projectId: data[5] as int,
    );
  }
}
