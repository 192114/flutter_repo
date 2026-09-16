import 'package:flutter/material.dart';

/// 应用颜色 token（shadcn 语义体系）。
///
/// 设计原则：
/// - 语义化命名（background / muted / destructive ...），与设计师的
///   设计稿 token 一一对应，填色零翻译；
/// - 运行时实例：挂到 ThemeData.extensions，随主题切换全树自动换肤。
///   **禁止**把颜色定义成 static const 常量类——那会让暗色模式形同虚设；
/// - [lerp] 必须逐字段实现：系统级明暗切换与 AnimatedTheme 过渡期间
///   Flutter 会对 ThemeExtension 做插值，缺失实现将在过渡期抛异常。
///
/// 消费方式：Widget 中统一使用 `context.colors`（见 theme_ext.dart），
/// 禁止散落 `Theme.of(context).extension<AppColors>()`。
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.success,
    required this.warning,
    required this.info,
  });

  /// 本套色板对应的亮度（lerp 时阶跃切换，不参与插值）。
  final Brightness brightness;

  // ==================== 基础 ====================
  /// 页面背景色。
  final Color background;

  /// 前景色（主文本）。
  final Color foreground;

  // ==================== 卡片 ====================
  /// 卡片 / 弹层背景色。
  final Color card;

  /// 卡片上的前景色。
  final Color cardForeground;

  // ==================== 主色 ====================
  /// 品牌主色（主按钮、选中态、焦点）。
  final Color primary;

  /// 主色之上的前景色。
  final Color primaryForeground;

  // ==================== 次要色 ====================
  /// 次要操作背景（次要按钮、标签底）。
  final Color secondary;

  /// 次要色之上的前景色。
  final Color secondaryForeground;

  // ==================== 弱化 ====================
  /// 弱化背景（输入框填充、分隔区块、禁用底）。
  final Color muted;

  /// 弱化前景（次要文本、占位符、说明文字）。
  final Color mutedForeground;

  // ==================== 强调 ====================
  /// 强调色（浅底强调区块，如头像底、高亮卡片）。
  final Color accent;

  /// 强调色之上的前景色。
  final Color accentForeground;

  // ==================== 危险 ====================
  /// 危险 / 错误色（删除、错误提示）。
  final Color destructive;

  /// 危险色之上的前景色。
  final Color destructiveForeground;

  // ==================== 描边 ====================
  /// 默认边框 / 分割线。
  final Color border;

  /// 输入框边框。
  final Color input;

  /// 焦点光环（输入框 focus、控件 focus ring）。
  final Color ring;

  // ==================== 状态色 ====================
  /// 成功。
  final Color success;

  /// 警告。
  final Color warning;

  /// 信息。
  final Color info;

  /// 浅色主题色板（品牌蓝基调 + shadcn zinc 中性色）。
  static const AppColors light = AppColors(
    brightness: Brightness.light,
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF09090B),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF09090B),
    primary: Color(0xFF4F6DF5),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFF4F4F5),
    secondaryForeground: Color(0xFF18181B),
    muted: Color(0xFFF4F4F5),
    mutedForeground: Color(0xFF71717A),
    accent: Color(0xFFEEF2FF),
    accentForeground: Color(0xFF3B53C7),
    destructive: Color(0xFFDC2626),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFE4E4E7),
    input: Color(0xFFE4E4E7),
    ring: Color(0xFF4F6DF5),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    info: Color(0xFF2563EB),
  );

  /// 深色主题色板（同语义、不同取值；主色提亮保证暗底对比度）。
  static const AppColors dark = AppColors(
    brightness: Brightness.dark,
    background: Color(0xFF09090B),
    foreground: Color(0xFFFAFAFA),
    card: Color(0xFF18181B),
    cardForeground: Color(0xFFFAFAFA),
    primary: Color(0xFF8B9DF9),
    primaryForeground: Color(0xFF101427),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    muted: Color(0xFF27272A),
    mutedForeground: Color(0xFFA1A1AA),
    accent: Color(0xFF262B45),
    accentForeground: Color(0xFFB9C4FB),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFF27272A),
    input: Color(0xFF3F3F46),
    ring: Color(0xFF8B9DF9),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
  );

  @override
  AppColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? foreground,
    Color? card,
    Color? cardForeground,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? accent,
    Color? accentForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return AppColors(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardForeground: cardForeground ?? this.cardForeground,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  /// 主题过渡插值：颜色逐字段 lerp，亮度阶跃切换。
  ///
  /// 不可省略：系统级明暗切换 / AnimatedTheme 过渡期间 Flutter 会调用本方法，
  /// 缺失或漏字段会在过渡期抛异常或闪色。
  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardForeground: Color.lerp(cardForeground, other.cardForeground, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground:
          Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground:
          Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(accentForeground, other.accentForeground, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground:
          Color.lerp(destructiveForeground, other.destructiveForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  /// 映射为 Material [ColorScheme]：业务代码不消费它，
  /// 仅供 Material 内置组件（Scaffold / Ripple / SnackBar 等）取色兜底。
  ///
  /// 所有用到的槽位全部显式指定，不依赖 ColorScheme 的缺省派生，
  /// 保证「每个颜色精确可控」。
  ColorScheme toColorScheme() {
    final isLight = brightness == Brightness.light;
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: primaryForeground,
      primaryContainer: accent,
      onPrimaryContainer: accentForeground,
      secondary: secondary,
      onSecondary: secondaryForeground,
      secondaryContainer: muted,
      onSecondaryContainer: mutedForeground,
      // tertiary 系列无独立语义，映射到 accent，防止缺省派生。
      tertiary: accent,
      onTertiary: accentForeground,
      tertiaryContainer: accent,
      onTertiaryContainer: accentForeground,
      error: destructive,
      onError: destructiveForeground,
      errorContainer: destructive,
      onErrorContainer: destructiveForeground,
      surface: background,
      onSurface: foreground,
      // surfaceContainer 五层级：无独立 token，归并到现有语义。
      surfaceContainerLowest: background,
      surfaceContainerLow: card,
      surfaceContainer: muted,
      surfaceContainerHigh: muted,
      surfaceContainerHighest: muted,
      onSurfaceVariant: mutedForeground,
      outline: input,
      outlineVariant: border,
      surfaceTint: primary,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      // inverse 系列用于 SnackBar 等反转组件：取对侧亮度的表面色。
      inverseSurface: isLight ? dark.card : light.secondary,
      onInverseSurface:
          isLight ? dark.cardForeground : light.secondaryForeground,
      inversePrimary: isLight ? dark.primary : light.primary,
    );
  }
}
