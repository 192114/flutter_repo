import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../exceptions/app_exception.dart';
import '../models/user.dart';
import 'dio_client.dart';

/// 用户相关 API 服务：仅封装 HTTP 请求与 JSON 反序列化。
///
/// 职责边界：
/// - 不做缓存、不做组合数据 —— 那是 Repository 的职责；
/// - 技术异常（DioException）由 Repository 统一映射为 AppException，
///   唯一例外：响应体为空（无法解析）时在此直接抛 [NotFoundException]。
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
    final data = response.data;
    if (data == null) {
      // HTTP 200 但响应体为空：视为资源不存在。
      // 直接 User.fromJson(response.data!) 会抛 Null check Error
      // （Error 而非 Exception），绕过 Repository 的异常映射，
      // 把技术细节泄露给 UI 层。
      throw const NotFoundException();
    }
    return User.fromJson(data);
  }
}

/// 依赖注入：UserApiService 的唯一装配点（共享全局 Dio 实例）。
final userApiServiceProvider = Provider<UserApiService>((ref) {
  return UserApiService(ref.watch(dioProvider));
});
