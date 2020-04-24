import 'package:freezed_annotation/freezed_annotation.dart';

part 'token.freezed.dart';
part 'token.g.dart';

@freezed
abstract class TokenData with _$TokenData {
  const factory TokenData(String token, int accountId, DateTime createdAt, {int id}) = _TokenData;

  factory TokenData.fromJson(Map<String, dynamic> json) => _$TokenDataFromJson(json);

  factory TokenData.fromDatabase(List<dynamic> data) {
    return TokenData(data[0] as String, data[1] as int, data[3] as DateTime, id: data[2] as int);
  }
}
