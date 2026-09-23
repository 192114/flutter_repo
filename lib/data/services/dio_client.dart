import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/logging/dio_logging_interceptor.dart';
import 'token_storage_service.dart';

/// 全局 Dio 实例 Provider（网络层唯一装配点）。
///
/// 统一配置 BaseUrl、超时时间与拦截器，所有 ApiService 共享同一个实例。
/// baseUrl / 超时等环境相关参数统一来自 [appConfigProvider]，
/// 由运行命令（--dart-define-from-file）决定，本文件零环境感知。
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref.watch(tokenStorageServiceProvider)));

  // 网络日志：统一走 AppLogger（debug 分级输出 / release 自动静默），
  // 替代原 LogInterceptor 的 print 系直出。
  dio.interceptors.add(DioLoggingInterceptor(ref.watch(appLoggerProvider)));

  // Provider 销毁时释放底层 HttpClient 连接。
  ref.onDispose(dio.close);

  return dio;
});

/// 请求鉴权拦截器：自动为每个请求附加 Bearer Token。
///
/// Token 读取自安全存储（[TokenStorageService]），
/// 业务代码无需关心鉴权细节。
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorageService _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
