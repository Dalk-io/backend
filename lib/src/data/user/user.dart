import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class UserData with _$UserData {
  @JsonSerializable(explicitToJson: true)
  const factory UserData(String id, {@JsonKey(includeIfNull: false) String name, @JsonKey(includeIfNull: false) String avatar}) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) => _$UserDataFromJson(json);

  factory UserData.fromDatabase(List<dynamic> data) => UserData(data[0] as String, name: data[1] as String, avatar: data[2] as String);
}
