import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import 'dio_client.dart';

/// 用户相关 API 服务：仅封装 HTTP 请求与 JSON 反序列化。
///
/// 职责边界：
/// - 不做缓存、不做组合数据 —— 那是 Repository 的职责；
/// - 不做错误语义转换 —— Repository 统一把 DioException 映射为 AppException。
class UserApiService {
  UserApiService(this._dio);

  final Dio _dio;

  /// GET /users —— 获取用户列表。
  Future<List<User>> fetchUsers() async {
    final response = await _dio.get<List<dynamic>>('/users');
    final data = response.data ?? const <dynamic>[];
    return data
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /users/:id —— 获取单个用户。
  Future<User> fetchUser(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/users/$id');
    return User.fromJson(response.data!);
  }
}

/// 依赖注入：UserApiService 的唯一装配点（共享全局 Dio 实例）。
final userApiServiceProvider = Provider<UserApiService>((ref) {
  return UserApiService(ref.watch(dioProvider));
});
