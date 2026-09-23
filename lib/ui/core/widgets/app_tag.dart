import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';

/// 标签样式：实心（填充底）与空心（描边）。
enum AppTagVariant { filled, outlined }

/// 标签语义色，对应设计稿五色行。
enum AppTagColor { primary, success, warning, danger, normal }

/// 标签尺寸（高度 24 / 28 / 32）。
enum AppTagSize { small, medium, large }

/// 标签：实心 / 空心 × 五语义色 × 三档尺寸，支持尾部关闭。
///
/// 规格（与设计稿一致）：
/// - 高度：小 24 / 中 28 / 大 32；圆角 4；
/// - 实心 success / warning 之上前景为 WCAG AA 校准的深/浅色字
///   （亮底深字、暗底浅字，非 background token）；
/// - 空心：透明底 + 1px 语义色描边 + 同色文字，normal 用 `input` 描边；
/// - [onClose] 非空时展示尾部 × 关闭按钮，点击触发回调。
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.variant = AppTagVariant.filled,
    this.color = AppTagColor.primary,
    this.size = AppTagSize.medium,
    this.onClose,
  });

  final String label;
  final AppTagVariant variant;
  final AppTagColor color;
  final AppTagSize size;

  /// 为 null 时不展示关闭按钮。
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (background, foreground, borderColor) = switch (variant) {
      AppTagVariant.filled => switch (color) {
        AppTagColor.primary => (colors.primary, colors.primaryForeground, null),
        AppTagColor.success => (colors.success, colors.successForeground, null),
        AppTagColor.warning => (colors.warning, colors.warningForeground, null),
        AppTagColor.danger => (
          colors.destructive,
          colors.destructiveForeground,
          null,
        ),
        AppTagColor.normal => (colors.muted, colors.secondaryForeground, null),
      },
      AppTagVariant.outlined => switch (color) {
        AppTagColor.primary => (
          Colors.transparent,
          colors.primary,
          colors.primary,
        ),
        AppTagColor.success => (
          Colors.transparent,
          colors.success,
          colors.success,
        ),
        AppTagColor.warning => (
          Colors.transparent,
          colors.warning,
          colors.warning,
        ),
        AppTagColor.danger => (
          Colors.transparent,
          colors.destructive,
          colors.destructive,
        ),
        AppTagColor.normal => (
          Colors.transparent,
          colors.mutedForeground,
          colors.input,
        ),
      },
    };

    final height = switch (size) {
      AppTagSize.small => 24.0,
      AppTagSize.medium => 28.0,
      AppTagSize.large => 32.0,
    };
    final fontSize = switch (size) {
      AppTagSize.small => 11.0,
      AppTagSize.medium => 12.0,
      AppTagSize.large => 14.0,
    };
    final horizontalPadding = size == AppTagSize.large
        ? AppSpacing.md
        : AppSpacing.sm;
    final closeIconSize = switch (size) {
      AppTagSize.small => 10.0,
      AppTagSize.medium => 12.0,
      AppTagSize.large => 14.0,
    };

    final tag = Container(
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsetsDirectional.only(
        start: horizontalPadding,
        end: onClose == null ? horizontalPadding : 0,
        top: 2,
        bottom: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.circular(AppRadius.xs),
        border: borderColor == null ? null : Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ),
          if (onClose != null) const SizedBox(width: 48),
        ],
      ),
    );

    if (onClose == null) return tag;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Stack(
        alignment: Alignment.center,
        children: [
          tag,
          Positioned.directional(
            textDirection: Directionality.of(context),
            end: 0,
            top: 0,
            bottom: 0,
            width: 48,
            child: Center(
              child: IconButton(
                onPressed: onClose,
                tooltip: AppLocalizations.of(context)!.deleteLabel(label),
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                padding: EdgeInsets.zero,
                icon: Icon(Icons.close, size: closeIconSize, color: foreground),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Tag · Light', group: 'Display', size: Size(420, 480))
Widget appTagLightPreview() => _tagPreview(AppTheme.light);

@Preview(name: 'Tag · Dark', group: 'Display', size: Size(420, 480))
Widget appTagDarkPreview() => _tagPreview(AppTheme.dark);

Widget _tagPreview(ThemeData theme) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  theme: theme,
  home: Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppTag(label: '主要'),
            AppTag(label: '成功', color: AppTagColor.success),
            AppTag(label: '警告', color: AppTagColor.warning),
            AppTag(label: '危险', color: AppTagColor.danger),
            AppTag(label: '默认', color: AppTagColor.normal),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppTag(label: '主要', variant: AppTagVariant.outlined),
            AppTag(
              label: '成功',
              variant: AppTagVariant.outlined,
              color: AppTagColor.success,
            ),
            AppTag(
              label: '警告',
              variant: AppTagVariant.outlined,
              color: AppTagColor.warning,
            ),
            AppTag(
              label: '危险',
              variant: AppTagVariant.outlined,
              color: AppTagColor.danger,
            ),
            AppTag(
              label: '默认',
              variant: AppTagVariant.outlined,
              color: AppTagColor.normal,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppTag(label: '标签', onClose: _noop),
            AppTag(
              label: '标签',
              variant: AppTagVariant.outlined,
              onClose: _noop,
            ),
            AppTag(label: '标签', color: AppTagColor.normal, onClose: _noop),
            AppTag(
              label: '标签',
              variant: AppTagVariant.outlined,
              color: AppTagColor.normal,
              onClose: _noop,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppTag(label: '小号', size: AppTagSize.small),
            AppTag(label: '中号'),
            AppTag(label: '大号', size: AppTagSize.large),
          ],
        ),
      ],
    ),
  ),
);

void _noop() {}
