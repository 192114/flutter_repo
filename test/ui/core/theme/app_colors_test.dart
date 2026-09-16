// AppColors token 单元测试：lerp 插值安全、ColorScheme 映射、实例挂载。

import 'package:flutter/material.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors.lerp', () {
    test('t=0 与 t=1 时分别等于两端实例', () {
      expect(AppColors.light.lerp(AppColors.dark, 0).primary,
          AppColors.light.primary);
      expect(AppColors.light.lerp(AppColors.dark, 1).primary,
          AppColors.dark.primary);
    });

    test('中间态逐字段插值且亮度阶跃', () {
      final mid = AppColors.light.lerp(AppColors.dark, 0.5);

      // 颜色为两端中间值。
      expect(
        mid.primary,
        Color.lerp(AppColors.light.primary, AppColors.dark.primary, 0.5),
      );
      // brightness 不参与插值，按 t 阶跃。
      expect(mid.brightness, Brightness.dark);
      expect(AppColors.light.lerp(AppColors.dark, 0.4).brightness,
          Brightness.light);
    });

    test('other 类型不匹配时返回自身（过渡期防崩溃）', () {
      expect(AppColors.light.lerp(null, 0.5), AppColors.light);
    });
  });

  group('toColorScheme 映射', () {
    test('关键槽位由 token 显式指定，不依赖派生', () {
      final scheme = AppColors.light.toColorScheme();

      expect(scheme.primary, AppColors.light.primary);
      expect(scheme.onPrimary, AppColors.light.primaryForeground);
      expect(scheme.error, AppColors.light.destructive);
      expect(scheme.surface, AppColors.light.background);
      expect(scheme.onSurfaceVariant, AppColors.light.mutedForeground);
      expect(scheme.outlineVariant, AppColors.light.border);
    });

    test('dark 实例映射出 dark 亮度的 ColorScheme', () {
      expect(AppColors.dark.toColorScheme().brightness, Brightness.dark);
    });
  });

  group('ThemeData 组装', () {
    test('AppTheme.light / dark 挂载对应 AppColors 实例', () {
      final light = AppTheme.light.extension<AppColors>();
      final dark = AppTheme.dark.extension<AppColors>();

      expect(light, AppColors.light);
      expect(dark, AppColors.dark);
    });
  });
}
