import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme_mode.dart';

/// 主题模式切换菜单（AppBar 入口）。
///
/// 主题偏好属于全局 UI 关注点而非业务状态，因此不经过业务 ViewModel，
/// 直接读写 [themeModeProvider]；选择结果持久化到本地。
class ThemeModeMenu extends ConsumerWidget {
  const ThemeModeMenu({super.key});

  static const _entries = <(ThemeMode, String, IconData)>[
    (ThemeMode.system, '跟随系统', Icons.brightness_auto_outlined),
    (ThemeMode.light, '浅色', Icons.light_mode_outlined),
    (ThemeMode.dark, '深色', Icons.dark_mode_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return PopupMenuButton<ThemeMode>(
      tooltip: '主题模式',
      icon: Icon(_iconFor(current)),
      onSelected: (mode) =>
          ref.read(themeModeProvider.notifier).setMode(mode),
      itemBuilder: (context) => [
        for (final (mode, label, icon) in _entries)
          PopupMenuItem<ThemeMode>(
            value: mode,
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
                if (mode == current) const Icon(Icons.check, size: 18),
              ],
            ),
          ),
      ],
    );
  }

  IconData _iconFor(ThemeMode mode) => switch (mode) {
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
        ThemeMode.system => Icons.brightness_auto_outlined,
      };
}
