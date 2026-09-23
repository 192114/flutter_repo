import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';

enum ToastType { success, error, warning, loading }

class FeedbackToast extends StatelessWidget {
  const FeedbackToast({super.key, required this.message, required this.type});

  final String message;
  final ToastType type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconColor = switch (type) {
      ToastType.success => colors.success,
      ToastType.error => colors.destructive,
      ToastType.warning => colors.warning,
      ToastType.loading => colors.primary,
    };

    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: type != ToastType.loading,
      label: l10n.toastAnnouncement(_labelFor(type, l10n), message),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: colors.border),
            borderRadius: AppRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDarkMode ? 0.28 : 0.1,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToastIcon(type: type, color: iconColor),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.cardForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _labelFor(ToastType toastType, AppLocalizations l10n) =>
      switch (toastType) {
        ToastType.success => l10n.success,
        ToastType.error => l10n.failure,
        ToastType.warning => l10n.warning,
        ToastType.loading => l10n.loading,
      };
}

class _ToastIcon extends StatelessWidget {
  const _ToastIcon({required this.type, required this.color});

  final ToastType type;
  final Color color;

  @override
  Widget build(BuildContext context) => switch (type) {
    ToastType.success => Icon(Icons.check_circle_outline, color: color),
    ToastType.error => Icon(Icons.cancel_outlined, color: color),
    ToastType.warning => Icon(Icons.warning_amber_rounded, color: color),
    ToastType.loading => SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(color: color, strokeWidth: 2),
    ),
  };
}

class ToastController {
  ToastController._();

  OverlayEntry? _entry;
  Timer? _timer;
  var _isDismissed = false;

  void _attach(OverlayEntry entry, Duration? duration) {
    _entry = entry;
    if (duration != null) {
      _timer = Timer(duration, dismiss);
    }
  }

  void dismiss() {
    if (_isDismissed) return;

    _isDismissed = true;
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    if (identical(_currentController, this)) _currentController = null;
    if (entry != null) {
      entry
        ..remove()
        ..dispose();
    }
  }
}

/// 当前 Toast 的控制器：新 Toast 到来时替换旧的而非叠加。
ToastController? _currentController;

abstract final class AppToast {
  static const _defaultDuration = Duration(seconds: 3);

  /// 加载提示无外部关闭时的兜底超时，避免永久滞留。
  static const _loadingFallbackDuration = Duration(seconds: 30);

  static ToastController success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) => show(
    context,
    message: message,
    type: ToastType.success,
    duration: duration,
  );

  static ToastController error(
    BuildContext context,
    String message, {
    Duration? duration,
  }) => show(
    context,
    message: message,
    type: ToastType.error,
    duration: duration,
  );

  static ToastController warning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) => show(
    context,
    message: message,
    type: ToastType.warning,
    duration: duration,
  );

  static ToastController loading(
    BuildContext context,
    String message, {
    Duration? duration,
  }) => show(
    context,
    message: message,
    type: ToastType.loading,
    duration: duration,
  );

  static ToastController show(
    BuildContext context, {
    required String message,
    required ToastType type,
    Duration? duration,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    // 单槽替换：新提示直接顶掉旧提示，避免多次操作叠出提示堆。
    _currentController?.dismiss();

    final controller = ToastController._();
    final entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: IgnorePointer(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: FeedbackToast(message: message, type: type),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    controller._attach(
      entry,
      duration ??
          (type == ToastType.loading
              ? _loadingFallbackDuration
              : _defaultDuration),
    );
    _currentController = controller;
    return controller;
  }
}

@Preview(name: 'Toast · Light', group: 'Feedback', size: Size(420, 360))
Widget feedbackToastLightPreview() => _toastPreview(AppTheme.light);

@Preview(name: 'Toast · Dark', group: 'Feedback', size: Size(420, 360))
Widget feedbackToastDarkPreview() => _toastPreview(AppTheme.dark);

Widget _toastPreview(ThemeData theme) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  theme: theme,
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: const [
            FeedbackToast(message: '操作成功', type: ToastType.success),
            FeedbackToast(message: '操作失败', type: ToastType.error),
            FeedbackToast(message: '请注意检查', type: ToastType.warning),
            FeedbackToast(message: '加载中…', type: ToastType.loading),
          ],
        ),
      ),
    ),
  ),
);
