import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 主题消费收口：Widget 中取颜色 token 的唯一入口。
///
/// 用法：`context.colors.primary`、`context.colors.mutedForeground`。
/// 禁止在业务代码中散落 `Theme.of(context).extension<AppColors>()`，
/// 便于统一检索、重构与替换。
extension AppThemeContext on BuildContext {
  /// 当前生效的颜色 token（随明/暗主题切换自动变化）。
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// 当前是否处于深色模式。
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
