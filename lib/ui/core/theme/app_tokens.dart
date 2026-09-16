import 'package:flutter/material.dart';

/// 布局 token：间距体系（4px 栅格）。
///
/// 间距不随主题（明/暗）变化，因此保持 `static const` 编译期常量：
/// 可用于 const 构造、无需 BuildContext，性能与便利性最优。
/// 只有「随主题变化的 token」（如颜色）才需要挂到 ThemeExtension。
abstract final class AppSpacing {
  /// 4px - 超小间距（图标与文字等紧凑场景）。
  static const double xs = 4;

  /// 8px - 小间距。
  static const double sm = 8;

  /// 12px - 中小间距。
  static const double md = 12;

  /// 16px - 标准间距（页面水平内边距）。
  static const double lg = 16;

  /// 20px - 中大间距。
  static const double xl = 20;

  /// 24px - 大间距。
  static const double xxl = 24;

  /// 32px - 超大间距。
  static const double xxxl = 32;

  /// 页面水平内边距。
  static const double pageHorizontal = lg;
}

/// 圆角 token：统一组件圆角阶梯。
///
/// 与 [AppSpacing] 同理，保持 `static const`。
abstract final class AppRadius {
  /// 4px - 超小圆角（小徽标等）。
  static const double xs = 4;

  /// 8px - 小圆角（Chip 等）。
  static const double sm = 8;

  /// 12px - 标准圆角（输入框、卡片）。
  static const double md = 12;

  /// 16px - 大圆角（大卡片）。
  static const double lg = 16;

  /// 24px - 超大圆角。
  static const double xl = 24;

  /// 完全圆形（头像、胶囊按钮）。
  static const double full = 999;

  /// 统一圆角快捷方法。
  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
}
