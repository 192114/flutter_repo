import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/theme_mode_storage.dart';

/// 主题模式状态：system（跟随系统）/ light / dark。
///
/// 初始值在 [build] 中从本地存储同步恢复（组合根已保证
/// SharedPreferences 实例就绪）；用户切换时落盘优先，
/// 落盘成功后才更新内存状态。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref.watch(themeModeStorageProvider).read();
    // 非法 / 缺失值一律回落 system（跟随系统是安全默认）。
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
  }

  /// 切换主题模式：先持久化，再更新状态。
  Future<void> setMode(ThemeMode mode) async {
    await ref.read(themeModeStorageProvider).save(mode.name);
    state = mode;
  }
}

/// 主题模式 Provider：app.dart 中 `themeMode: ref.watch(themeModeProvider)`。
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
