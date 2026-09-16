import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// 应用统一日志出口（横切关注点，与 data / ui 层平级）。
///
/// 约定：
/// - 全应用禁止直接依赖 logger 包或调用 print，统一经 [AppLogger] 记录；
/// - debug 模式：PrettyPrinter 彩色分级输出到控制台；
/// - release 模式：默认 DevelopmentFilter 全静默 —— 零 IO、零信息泄漏；
/// - 未来接入远程上报（Sentry / Crashlytics）时，替换内部实现即可，
///   所有调用点零改动。
class AppLogger {
  AppLogger({Logger? logger}) : _logger = logger ?? _createDefaultLogger();

  /// 生产默认配置：彩色美化输出。
  static Logger _createDefaultLogger() {
    return Logger(
      printer: PrettyPrinter(
        // 普通日志不打印调用栈保持输出干净；错误日志打印堆栈（默认 8 帧）。
        methodCount: 0,
        lineLength: 100,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }

  final Logger _logger;

  /// 调试信息：高频流程跟踪（网络请求 / 响应等）。
  void d(String message) => _logger.d(message);

  /// 重要流程节点（初始化完成、登录成功等）。
  void i(String message) => _logger.i(message);

  /// 可恢复的异常或可疑状态。
  void w(String message) => _logger.w(message);

  /// 错误：携带异常对象与堆栈。
  void e(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// 致命错误：即将导致功能不可用或崩溃。
  void f(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}

/// 依赖注入：AppLogger 的唯一装配点。
///
/// 测试时可注入带自定义 LogOutput 的实例以捕获日志做断言。
final appLoggerProvider = Provider<AppLogger>((ref) {
  return AppLogger();
});
