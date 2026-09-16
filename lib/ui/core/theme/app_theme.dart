import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// 全局主题组装（Material 3）。
///
/// 颜色唯一真相源是 [AppColors]（shadcn 语义 token，见 app_colors.dart）：
/// - 业务组件消费 `context.colors`（ThemeExtension 分发，随主题切换换肤）；
/// - Material 内置组件消费 [AppColors.toColorScheme] 映射出的 ColorScheme；
/// - 不再使用 ColorScheme.fromSeed——每个颜色值精确指定，零算法派生。
abstract final class AppTheme {
  /// 浅色主题。
  static ThemeData get light => _build(AppColors.light);

  /// 深色主题。
  static ThemeData get dark => _build(AppColors.dark);

  static ThemeData _build(AppColors colors) {
    final radius = BorderRadius.circular(AppRadius.md);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors.toColorScheme(),
      // ThemeExtension 挂载点：AppColors 实例随 ThemeData 分发。
      extensions: [colors],
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card,
        hintStyle: TextStyle(color: colors.mutedForeground),
        prefixIconColor: colors.mutedForeground,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.ring, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}
