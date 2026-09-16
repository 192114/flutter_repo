import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// 用户实体（不可变模型）。
///
/// freezed 自动生成 `copyWith` / `==` / `hashCode` / `toString`，
/// json_serializable 自动生成 `fromJson` / `toJson`。
///
/// 不可变性是单向数据流的基石：
/// 状态只能被「替换」而不能被「原地修改」，可安全跨层传递。
@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required String name,
    @Default('') String username,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String website,
    Company? company,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// 用户所属公司（不可变模型）。
@freezed
abstract class Company with _$Company {
  const factory Company({
    @Default('') String name,
    @Default('') String catchPhrase,
  }) = _Company;

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);
}
