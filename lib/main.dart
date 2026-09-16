import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'data/services/user_local_service.dart';

Future<void> main() async {
  // 使用异步插件（SharedPreferences 等）前必须初始化 binding。
  WidgetsFlutterBinding.ensureInitialized();

  // 启动环境确认：环境由运行命令注入，缺省回落 dev。
  //   fvm flutter run --dart-define-from-file=env/dev.json
  //   fvm flutter run --dart-define-from-file=env/prod.json
  // 组合根期直接读编译期常量（AppLogger 此处为组装日志，debug 输出）。
  final config = AppConfig.fromEnvironment();
  AppLogger().i('启动环境: ${config.environment.label} · ${config.baseUrl}');

  // ── 组合根（Composition Root）───────────────────────────────
  // 所有需要「异步初始化」的依赖在 main 中一次性完成创建，
  // 再通过 ProviderScope.overrides 注入容器。
  // 业务层（Service / Repository / ViewModel）从此零感知初始化细节。
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // 预初始化实例 → 覆盖 Provider 的默认实现。
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),

        // userRepositoryProvider 默认绑定生产实现（UserRepositoryImpl），
        // 测试 / Demo 环境在此处一行切换：
        // userRepositoryProvider.overrideWithValue(FakeUserRepository()),
      ],
      child: const App(),
    ),
  );
}
