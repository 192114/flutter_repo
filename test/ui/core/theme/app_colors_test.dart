// AppColors token 单元测试：lerp 插值安全、ColorScheme 映射、实例挂载。

import 'package:flutter/material.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppColors.lerp', () {
    test('t=0 与 t=1 时分别等于两端实例', () {
      expect(
        AppColors.light.lerp(AppColors.dark, 0).primary,
        AppColors.light.primary,
      );
      expect(
        AppColors.light.lerp(AppColors.dark, 1).primary,
        AppColors.dark.primary,
      );
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
      expect(
        AppColors.light.lerp(AppColors.dark, 0.4).brightness,
        Brightness.light,
      );
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

  group('success/warning 前景 token', () {
    for (final colors in [AppColors.light, AppColors.dark]) {
      test('${colors.brightness.name} 的 copyWith 保留或独立覆盖新 token', () {
        final unchanged = colors.copyWith(primary: Colors.purple);
        expect(unchanged.successForeground, colors.successForeground);
        expect(unchanged.warningForeground, colors.warningForeground);

        final successOnly = colors.copyWith(successForeground: Colors.black);
        expect(successOnly.successForeground, Colors.black);
        expect(successOnly.warningForeground, colors.warningForeground);
        expect(successOnly.success, colors.success);

        final warningOnly = colors.copyWith(warningForeground: Colors.white);
        expect(warningOnly.warningForeground, Colors.white);
        expect(warningOnly.successForeground, colors.successForeground);
        expect(warningOnly.warning, colors.warning);
      });

      for (final (name, foreground, background) in [
        ('success', colors.successForeground, colors.success),
        ('warning', colors.warningForeground, colors.warning),
      ]) {
        test('${colors.brightness.name} $name 前景/底色对比度达到 4.5:1', () {
          final first = foreground.computeLuminance();
          final second = background.computeLuminance();
          final ratio = first > second
              ? (first + 0.05) / (second + 0.05)
              : (second + 0.05) / (first + 0.05);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$name contrast: $ratio',
          );
        });
      }
    }

    test('自定义主题 copyWith 与 ThemeData.lerp 传播新 token', () {
      final start = AppColors.light.copyWith(
        successForeground: const Color(0xFF102030),
        warningForeground: const Color(0xFF405060),
      );
      final end = AppColors.dark.copyWith(
        successForeground: const Color(0xFFA0B0C0),
        warningForeground: const Color(0xFFD0E0F0),
      );
      final startTheme = AppTheme.light.copyWith(extensions: [start]);
      final endTheme = AppTheme.dark.copyWith(extensions: [end]);
      final copied = startTheme
          .copyWith(scaffoldBackgroundColor: Colors.pink)
          .extension<AppColors>()!;
      expect(copied.successForeground, start.successForeground);
      expect(copied.warningForeground, start.warningForeground);

      for (final t in [0.0, 0.25, 0.5, 1.0]) {
        for (final interpolated in [
          start.lerp(end, t),
          ThemeData.lerp(startTheme, endTheme, t).extension<AppColors>()!,
        ]) {
          expect(
            interpolated.successForeground,
            Color.lerp(start.successForeground, end.successForeground, t),
          );
          expect(
            interpolated.warningForeground,
            Color.lerp(start.warningForeground, end.warningForeground, t),
          );
        }
      }
    });
  });
}
