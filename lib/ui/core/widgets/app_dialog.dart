import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';

enum AppDialogIntent { normal, destructive }

class AppAlertDialog extends StatelessWidget {
  const AppAlertDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.confirmLabel,
    this.onConfirm,
  }) : assert(message == null || content == null);

  final String title;
  final String? message;
  final Widget? content;
  final String? confirmLabel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _CenteredDialogFrame(
      accentColor: colors.info,
      icon: Icon(Icons.info_outline, color: colors.info, size: 28),
      title: title,
      message: message,
      content: content,
      actions: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.primaryForeground,
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.circular(AppRadius.sm + 2),
            ),
          ),
          child: Text(
            confirmLabel ?? AppLocalizations.of(context)!.acknowledge,
          ),
        ),
      ),
    );
  }
}

class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.intent = AppDialogIntent.normal,
    this.cancelLabel,
    this.confirmLabel,
    this.onCancel,
    this.onConfirm,
  }) : assert(message == null || content == null);

  final String title;
  final String? message;
  final Widget? content;
  final AppDialogIntent intent;
  final String? cancelLabel;
  final String? confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final destructive = intent == AppDialogIntent.destructive;
    final accent = destructive ? colors.destructive : colors.primary;

    return _CenteredDialogFrame(
      accentColor: accent,
      icon: Icon(
        destructive ? Icons.error_outline : Icons.info_outline,
        color: accent,
        size: 28,
      ),
      title: title,
      message: message,
      content: content,
      actions: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.secondaryForeground,
                minimumSize: const Size.fromHeight(44),
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.circular(AppRadius.sm + 2),
                ),
              ),
              child: Text(cancelLabel ?? AppLocalizations.of(context)!.cancel),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: destructive
                    ? colors.destructiveForeground
                    : colors.primaryForeground,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.circular(AppRadius.sm + 2),
                ),
              ),
              child: Text(
                confirmLabel ?? AppLocalizations.of(context)!.confirm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredDialogFrame extends StatelessWidget {
  const _CenteredDialogFrame({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.message,
    required this.content,
    required this.actions,
  });

  final Color accentColor;
  final Widget icon;
  final String title;
  final String? message;
  final Widget? content;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: icon),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.cardForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null || content != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: SingleChildScrollView(
                    child:
                        content ??
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.mutedForeground,
                            height: 1.5,
                          ),
                        ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              actions,
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class AppDialogs {
  static Future<void> showAlert(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    String? confirmLabel,
    bool barrierDismissible = true,
  }) async {
    assert(message == null || content == null);
    await showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppAlertDialog(
        title: title,
        message: message,
        content: content,
        confirmLabel: confirmLabel,
        onConfirm: () => _close(context),
      ),
    );
  }

  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    AppDialogIntent intent = AppDialogIntent.normal,
    String? cancelLabel,
    String? confirmLabel,
    bool barrierDismissible = true,
  }) {
    assert(message == null || content == null);
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AppConfirmDialog(
        title: title,
        message: message,
        content: content,
        intent: intent,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        onCancel: () => _close(context, false),
        onConfirm: () => _close(context, true),
      ),
    );
  }

  static void _close(BuildContext context, [bool? result]) {
    if (context.mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop(result);
    }
  }
}

@Preview(name: 'Dialog · Light', group: 'Feedback', size: Size(420, 680))
Widget feedbackDialogLightPreview() => _dialogPreview(AppTheme.light);

@Preview(name: 'Dialog · Dark', group: 'Feedback', size: Size(420, 680))
Widget feedbackDialogDarkPreview() => _dialogPreview(AppTheme.dark);

Widget _dialogPreview(ThemeData theme) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  theme: theme,
  home: Scaffold(
    body: ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: const [
        AppAlertDialog(title: '提示', message: '您的操作已完成，感谢使用。'),
        AppConfirmDialog(
          title: '删除确认',
          message: '删除后无法恢复，确定要删除此内容吗？',
          intent: AppDialogIntent.destructive,
          confirmLabel: '确认删除',
        ),
      ],
    ),
  ),
);
