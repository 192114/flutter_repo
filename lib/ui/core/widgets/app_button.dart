import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';

/// 按钮变体，对应设计稿「样式」行。
enum AppButtonVariant { primary, secondary, outline, destructive, text }

/// 按钮尺寸，对应设计稿「尺寸」行（高度 44 / 36 / 28）。
enum AppButtonSize { large, medium, small }

/// 移动端按钮：变体 × 尺寸 × 加载 / 禁用态。
///
/// 规格（与设计稿一致）：
/// - 高度：大 44 / 中 36 / 小 28；圆角：大、中 12，小 8；
/// - 禁用：底 `muted`、字 `mutedForeground`（text 变体仅文字变灰）；
/// - 加载：变体前景色转圈 + 文案，期间屏蔽点击。
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.loading = false,
    this.expand = false,
    this.icon,
    this.leading,
    this.trailing,
  }) : assert(icon == null || leading == null);

  final String label;

  /// 为 null 时进入禁用态。
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading;

  /// 是否撑满父级宽度。
  final bool expand;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = _enabled;

    final (background, foreground, border) = switch (variant) {
      AppButtonVariant.primary => (
        colors.primary,
        colors.primaryForeground,
        null,
      ),
      AppButtonVariant.secondary => (
        colors.secondary,
        colors.secondaryForeground,
        null,
      ),
      AppButtonVariant.outline => (
        colors.card,
        colors.cardForeground,
        BorderSide(color: colors.input),
      ),
      AppButtonVariant.destructive => (
        colors.destructive,
        colors.destructiveForeground,
        null,
      ),
      AppButtonVariant.text => (Colors.transparent, colors.primary, null),
    };

    // 加载中仍属可等待的进行态：保持变体配色，仅屏蔽点击；
    // 真正禁用（onPressed 为 null）才转灰底。
    final showDisabledStyle = !enabled && !loading;
    final effectiveBackground = switch (variant) {
      AppButtonVariant.text => Colors.transparent,
      _ => showDisabledStyle ? colors.muted : background,
    };
    final effectiveForeground = showDisabledStyle
        ? colors.mutedForeground
        : foreground;

    final height = switch (size) {
      AppButtonSize.large => 44.0,
      AppButtonSize.medium => 36.0,
      AppButtonSize.small => 28.0,
    };
    final radius = size == AppButtonSize.small ? AppRadius.sm : AppRadius.md;
    final textStyle = switch (size) {
      AppButtonSize.large => Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      AppButtonSize.medium => Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      AppButtonSize.small => Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
    };

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: effectiveForeground,
            ),
          )
        else if (leading != null)
          leading!
        else if (icon != null)
          Icon(icon, size: 18, color: effectiveForeground),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: textStyle?.copyWith(color: effectiveForeground),
          ),
        ),
        ?trailing,
      ],
    );

    return SizedBox(
      width: expand ? double.infinity : null,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor: effectiveBackground,
          foregroundColor: effectiveForeground,
          disabledBackgroundColor: effectiveBackground,
          disabledForegroundColor: effectiveForeground,
          minimumSize: Size(0, height),
          padding: EdgeInsets.symmetric(
            horizontal: size == AppButtonSize.small
                ? AppSpacing.md
                : AppSpacing.lg,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.standard,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.circular(radius),
            side: border ?? BorderSide.none,
          ),
        ),
        child: IconTheme.merge(
          data: IconThemeData(size: 18, color: effectiveForeground),
          child: child,
        ),
      ),
    );
  }
}

@Preview(name: 'Button · Light', group: 'Form', size: Size(420, 560))
Widget appButtonLightPreview() => _buttonPreview(AppTheme.light);

@Preview(name: 'Button · Dark', group: 'Form', size: Size(420, 560))
Widget appButtonDarkPreview() => _buttonPreview(AppTheme.dark);

Widget _buttonPreview(ThemeData theme) => MaterialApp(
  theme: theme,
  home: Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        AppButton(label: '主按钮', onPressed: _noop),
        SizedBox(height: AppSpacing.sm),
        AppButton(
          label: '次要',
          variant: AppButtonVariant.secondary,
          onPressed: _noop,
        ),
        SizedBox(height: AppSpacing.sm),
        AppButton(
          label: '描边',
          variant: AppButtonVariant.outline,
          onPressed: _noop,
        ),
        SizedBox(height: AppSpacing.sm),
        AppButton(
          label: '危险',
          variant: AppButtonVariant.destructive,
          onPressed: _noop,
        ),
        SizedBox(height: AppSpacing.sm),
        AppButton(
          label: '文字',
          variant: AppButtonVariant.text,
          onPressed: _noop,
        ),
        SizedBox(height: AppSpacing.sm),
        AppButton(label: '禁用'),
        SizedBox(height: AppSpacing.sm),
        AppButton(label: '加载中', loading: true, onPressed: _noop),
        SizedBox(height: AppSpacing.sm),
        Row(
          spacing: AppSpacing.sm,
          children: [
            AppButton(
              label: '中号',
              size: AppButtonSize.medium,
              onPressed: _noop,
            ),
            AppButton(label: '小号', size: AppButtonSize.small, onPressed: _noop),
          ],
        ),
      ],
    ),
  ),
);

void _noop() {}
