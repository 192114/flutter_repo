import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/core/router/app_router.dart';
import 'ui/core/theme/app_theme.dart';

/// 应用根组件。
///
/// main.dart 保持极薄（只做初始化 + 注入），
/// 根组件独立成 [App]，便于 widget 测试直接 pumpWidget，
/// 也便于在测试中通过外层 ProviderScope 覆盖依赖。
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 路由也是依赖：由 Provider 提供，测试时可整体替换。
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Flutter Repo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
