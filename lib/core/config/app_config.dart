import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';

/// 应用运行环境（编译期确定，运行期只读）。
enum AppEnvironment {
  dev('开发'),
  staging('预发'),
  prod('生产');

  const AppEnvironment(this.label);

  /// 面向日志 / 调试 UI 的中文标签。
  final String label;

  /// 解析 dart-define 注入的环境字符串。
  ///
  /// 非法 / 未知值一律回落 [dev]：
  /// 宁可连错环境也不要崩溃，且 dev 环境最安全（默认数据源）。
  static AppEnvironment parse(String value) => switch (value.toLowerCase()) {
    'staging' => staging,
    'prod' || 'production' => prod,
    _ => dev,
  };

  bool get isDev => this == dev;
}

/// 编译期注入的环境常量：`--dart-define-from-file=env/<env>.json`。
///
/// 每个常量都带安全缺省值 —— 不传任何 dart-define 直接 `flutter run`
/// 时自动回落 dev + 公共演示 API，保证工程开箱可跑。
///
/// 约定：这里只允许存放**非敏感**配置（baseUrl、超时等）。
/// API Key / Secret 等敏感值不得经 dart-define 注入
/// （它们会进入编译产物，可被提取），应由后端代理签发。
abstract final class EnvConstants {
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://jsonplaceholder.typicode.com',
  );

  // 保留原始输入，由 AppConfig.fromEnvironment 校验，避免非法整数静默回落。
  static const String apiConnectTimeoutMs = String.fromEnvironment(
    'API_CONNECT_TIMEOUT_MS',
    defaultValue: '10000',
  );

  static const String apiReceiveTimeoutMs = String.fromEnvironment(
    'API_RECEIVE_TIMEOUT_MS',
    defaultValue: '10000',
  );
}

/// 应用配置（不可变）。
///
/// 「环境载体 → 配置模型」的唯一收敛点：
/// 无论环境值来自 dart-define、flavor 还是测试 override，
/// 消费方（dioProvider 等）只认 [AppConfig]，不感知注入方式。
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    required AppEnvironment environment,
    required String baseUrl,
    @Default(Duration(seconds: 10)) Duration connectTimeout,
    @Default(Duration(seconds: 10)) Duration receiveTimeout,
  }) = _AppConfig;

  const AppConfig._();

  /// 解析并校验外部配置，默认读取编译期常量，也可传入原始字符串。
  ///
  /// URL 或超时非法时抛出仅包含配置键和约束的 [FormatException]。
  factory AppConfig.fromEnvironment({
    String environment = EnvConstants.environment,
    String baseUrl = EnvConstants.apiBaseUrl,
    String connectTimeoutMs = EnvConstants.apiConnectTimeoutMs,
    String receiveTimeoutMs = EnvConstants.apiReceiveTimeoutMs,
  }) => AppConfig(
    environment: AppEnvironment.parse(environment),
    baseUrl: _validateBaseUrl(baseUrl),
    connectTimeout: _parseTimeout(connectTimeoutMs, 'API_CONNECT_TIMEOUT_MS'),
    receiveTimeout: _parseTimeout(receiveTimeoutMs, 'API_RECEIVE_TIMEOUT_MS'),
  );
}

String _validateBaseUrl(String value) {
  const error = FormatException(
    'API_BASE_URL must be an absolute HTTP(S) URL with a non-empty host '
    'and a port between 1 and 65535 when specified.',
  );
  // Uri 会转义空白、规范化反斜杠和空端口，必须先检查原始输入。
  final authority = RegExp(
    r'^https?://([^/?#]*)',
    caseSensitive: false,
  ).firstMatch(value)?.group(1);
  if (authority == null ||
      RegExp(r'\s').hasMatch(value) ||
      value.contains('\\')) {
    throw error;
  }
  // 排除 userInfo 和 IPv6 内部的冒号，显式端口只允许十进制数字。
  final hostAndPort = authority.substring(authority.lastIndexOf('@') + 1);
  final portSeparator = hostAndPort.lastIndexOf(':');
  if (portSeparator > hostAndPort.lastIndexOf(']') &&
      !RegExp(r'^[0-9]+$').hasMatch(hostAndPort.substring(portSeparator + 1))) {
    throw error;
  }

  try {
    final uri = Uri.parse(value);
    if (!uri.hasScheme ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.port < 1 ||
        uri.port > 65535) {
      throw error;
    }
  } on FormatException {
    // Uri 的异常可能携带完整 URL（含凭据、查询参数），不得向外传播。
    throw error;
  }
  return value;
}

Duration _parseTimeout(String value, String key) {
  final error = FormatException(
    '$key must be a positive integer in milliseconds.',
  );
  final milliseconds = int.tryParse(value, radix: 10);
  if (milliseconds == null || milliseconds <= 0) throw error;
  final timeout = Duration(milliseconds: milliseconds);
  // Duration 内部使用微秒，合法 int 的毫秒数仍可能溢出。
  if (timeout.inMilliseconds != milliseconds) throw error;
  return timeout;
}

/// 应用配置唯一出口。
///
/// - 默认从编译期环境常量组装（运行命令决定环境）；
/// - 测试 / Demo 环境可在 ProviderScope 中一行 overrideWithValue 替换，
///   例如把 baseUrl 指向本地 mock server。
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
