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

  static const int apiConnectTimeoutMs = int.fromEnvironment(
    'API_CONNECT_TIMEOUT_MS',
    defaultValue: 10000,
  );

  static const int apiReceiveTimeoutMs = int.fromEnvironment(
    'API_RECEIVE_TIMEOUT_MS',
    defaultValue: 10000,
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

  /// 从编译期环境常量组装配置（组合根 / Provider 默认实现使用）。
  factory AppConfig.fromEnvironment() => AppConfig(
        environment: AppEnvironment.parse(EnvConstants.environment),
        baseUrl: EnvConstants.apiBaseUrl,
        connectTimeout: Duration(milliseconds: EnvConstants.apiConnectTimeoutMs),
        receiveTimeout:
            Duration(milliseconds: EnvConstants.apiReceiveTimeoutMs),
      );
}

/// 应用配置唯一出口。
///
/// - 默认从编译期环境常量组装（运行命令决定环境）；
/// - 测试 / Demo 环境可在 ProviderScope 中一行 overrideWithValue 替换，
///   例如把 baseUrl 指向本地 mock server。
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
