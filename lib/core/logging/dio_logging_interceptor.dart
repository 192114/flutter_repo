import 'package:dio/dio.dart';

import 'app_logger.dart';

/// 网络日志拦截器：把 HTTP 请求 / 响应 / 异常统一路由到 [AppLogger]。
///
/// 分级约定：
/// - 请求 / 响应 → [AppLogger.d]（高频流水，release 自动静默）；
/// - 异常 → [AppLogger.e]（含 DioException 与堆栈）。
///
/// 本拦截器不含任何环境判断 —— 静默策略统一由 AppLogger 的
/// Filter 负责，保持职责单一。
class DioLoggingInterceptor extends Interceptor {
  DioLoggingInterceptor(this._logger);

  /// extra 中记录请求起始时间戳的 key（用于计算耗时）。
  static const String _startTimeKey = 'dio_logging_start_ms';

  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;
    _logger.d('HTTP → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final elapsed = _elapsed(response.requestOptions);
    _logger.d(
      'HTTP ← ${response.requestOptions.method} '
      '${response.requestOptions.uri} ${response.statusCode}'
      '${elapsed == null ? '' : ' ($elapsed ms)'}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      'HTTP ✕ ${err.requestOptions.method} ${err.requestOptions.uri}',
      error: err,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }

  /// 计算请求耗时；起始时间戳缺失时返回 null（容忍异常路径）。
  String? _elapsed(RequestOptions options) {
    final startMs = options.extra[_startTimeKey];
    if (startMs is! int) {
      return null;
    }
    return (DateTime.now().millisecondsSinceEpoch - startMs).toString();
  }
}
