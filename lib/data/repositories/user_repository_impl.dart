import 'package:dio/dio.dart';

import '../../core/logging/app_logger.dart';
import '../exceptions/app_exception.dart';
import '../models/user.dart';
import '../services/user_api_service.dart';
import '../services/user_local_service.dart';
import 'user_repository.dart';

/// [UserRepository] 的生产实现。
///
/// 职责：
/// 1. 组合多个数据源（远端 API + 本地存储），向上暴露统一接口；
/// 2. 把底层技术异常转换为语义化的 [AppException]，
///    使 UI 层完全不必感知 Dio / SharedPreferences 的存在。
class UserRepositoryImpl implements UserRepository {
  // Dart 3.7+ 私有字段命名参数：对外参数名自动去下划线（apiService / localService）。
  UserRepositoryImpl({
    required this._apiService,
    required this._localService,
    required this._logger,
  });

  final UserApiService _apiService;
  final UserLocalService _localService;
  final AppLogger _logger;

  @override
  Future<List<User>> getUsers() async {
    try {
      return await _apiService.fetchUsers();
    } on DioException catch (e) {
      final exception = _toAppException(e);
      // 语义层日志（拦截器已记录技术层 DioException，两者信息互补）。
      _logger.e('获取用户列表失败', error: exception);
      throw exception;
    } on AppException {
      // Service 层已语义化的异常（如空响应体 NotFound）直接透传。
      rethrow;
    } on Object catch (e, stackTrace) {
      // 反序列化边界异常（字段缺失 / 类型不符抛出的是 TypeError，
      // 不是 Exception，会绕过上面的捕获）：统一收敛为 UnknownException。
      _logger.e('获取用户列表失败（响应解析异常）', error: e, stackTrace: stackTrace);
      throw const UnknownException();
    }
  }

  @override
  Future<User> getUser(int id) async {
    try {
      return await _apiService.fetchUser(id);
    } on DioException catch (e) {
      final exception = _toAppException(e);
      _logger.e('获取用户(id: $id)详情失败', error: exception);
      throw exception;
    } on AppException {
      rethrow;
    } on Object catch (e, stackTrace) {
      _logger.e('获取用户(id: $id)详情失败（响应解析异常）', error: e, stackTrace: stackTrace);
      throw const UnknownException();
    }
  }

  @override
  Future<Set<int>> getFavoriteIds() async {
    try {
      return _localService.readFavoriteIds();
    } on Exception catch (e) {
      _logger.e('读取收藏状态失败', error: e);
      throw const CacheException();
    }
  }

  @override
  Future<Set<int>> toggleFavorite(int userId) async {
    try {
      return await _localService.toggleFavorite(userId);
    } on Exception catch (e) {
      _logger.e('切换收藏(id: $userId)失败', error: e);
      throw const CacheException();
    }
  }

  /// DioException → AppException 的映射。
  AppException _toAppException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => const NetworkException(),
      DioExceptionType.badResponse when e.response?.statusCode == 404 =>
        const NotFoundException(),
      _ => const UnknownException(),
    };
  }
}
