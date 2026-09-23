import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_toast.dart';
import 'gallery_section.dart';

class FeedbackDemoScreen extends StatelessWidget {
  const FeedbackDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('反馈组件')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 720 ? 720 : double.infinity,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  '反馈组件演示',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '查看轻提示与弹窗在当前主题下的真实交互效果。',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.mutedForeground),
                ),
                const SizedBox(height: AppSpacing.xxl),
                GallerySection(
                  title: '轻提示',
                  description: '用于反馈短暂且无需用户决策的操作状态。',
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _ToastAction(
                        key: const Key('toast-success'),
                        label: '成功',
                        icon: Icons.check_circle_outline,
                        color: colors.success,
                        onPressed: () => AppToast.success(context, '操作成功'),
                      ),
                      _ToastAction(
                        key: const Key('toast-error'),
                        label: '失败',
                        icon: Icons.cancel_outlined,
                        color: colors.destructive,
                        onPressed: () => AppToast.error(context, '操作失败'),
                      ),
                      _ToastAction(
                        key: const Key('toast-warning'),
                        label: '警告',
                        icon: Icons.warning_amber_rounded,
                        color: colors.warning,
                        onPressed: () => AppToast.warning(context, '请注意检查'),
                      ),
                      _ToastAction(
                        key: const Key('toast-loading'),
                        label: '加载中',
                        icon: Icons.refresh_rounded,
                        color: colors.primary,
                        onPressed: () => AppToast.loading(
                          context,
                          '加载中…',
                          duration: const Duration(seconds: 2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GallerySection(
                  title: '弹窗',
                  description: '用于需要用户阅读或确认的重要操作。',
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('dialog-alert'),
                        onPressed: () => unawaited(
                          AppDialogs.showAlert(
                            context,
                            title: '提示',
                            message: '您的操作已完成，感谢使用。',
                          ),
                        ),
                        icon: Icon(Icons.info_outline, color: colors.info),
                        label: const Text('提示弹窗'),
                      ),
                      FilledButton.icon(
                        key: const Key('dialog-confirm'),
                        onPressed: () => unawaited(
                          AppDialogs.showConfirm(
                            context,
                            title: '删除确认',
                            message: '删除后无法恢复，确定要删除此内容吗？',
                            intent: AppDialogIntent.destructive,
                            confirmLabel: '确认删除',
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.destructive,
                          foregroundColor: colors.destructiveForeground,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('确认弹窗'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastAction extends StatelessWidget {
  const _ToastAction({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color),
    ),
    icon: Icon(icon),
    label: Text(label),
  );
}
