import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'data/services/shared_preferences_provider.dart';
import 'ui/core/widgets/startup_failure_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();
  await bootstrap();
}

Future<void> bootstrap({
  AppConfig Function() loadConfig = AppConfig.fromEnvironment,
  Future<SharedPreferences> Function() loadPreferences =
      SharedPreferences.getInstance,
}) async {
  try {
    final config = loadConfig();
    AppLogger().i('启动环境: ${config.environment.label} · ${config.baseUrl}');
    final sharedPreferences = await loadPreferences();

    runApp(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const App(),
      ),
    );
  } on Object catch (error, stackTrace) {
    AppLogger().e('应用初始化失败', error: error, stackTrace: stackTrace);
    runApp(
      ProviderScope(
        // 恢复后必须新建容器，避免在已有容器上改变 overrides 数量。
        key: const ValueKey('startup-failure'),
        child: StartupFailureApp(
          onRetry: () => bootstrap(
            loadConfig: loadConfig,
            loadPreferences: loadPreferences,
          ),
        ),
      ),
    );
  }
}

/// 安装全局兜底错误处理（也是将来接入 Crashlytics / Sentry 的唯一挂点）。
///
/// - [FlutterError.onError]：Framework 异常（build / layout 抛错等）；
/// - [PlatformDispatcher.onError]：Zone 之外未捕获的异步异常。
void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    AppLogger().f(
      'Flutter 框架异常',
      error: details.exception,
      stackTrace: details.stack,
    );
    // 保持默认行为：debug 下仍输出控制台并渲染 ErrorWidget。
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger().f('未捕获异常', error: error, stackTrace: stackTrace);
    // debug：AppLogger 已输出，返回 true 抑制控制台重复噪音；
    // release：AppLogger 静默，返回 false 交还平台默认处理，
    // 保留 stderr / logcat 中的崩溃痕迹，避免异常被完全吞掉。
    return !kReleaseMode;
  };
}
