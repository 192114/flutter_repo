import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/theme_ext.dart';

/// [AsyncValue] 通用渲染组件：统一 Loading / Error / Data 三态展示。
///
/// 属于共享 UI 组件（UI Layer core），任何 Feature 均可复用，
/// 避免每个 Screen 重复编写三态切换逻辑。
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.errorMessageBuilder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  /// ViewModel 暴露的异步状态。
  final AsyncValue<T> value;

  /// 数据就绪时的渲染回调。
  final Widget Function(T data) data;

  /// 错误重试回调（为空则不显示重试按钮）。
  final VoidCallback? onRetry;

  /// 把异常映射为安全的用户文案，缺省不暴露异常详情。
  final String Function(Object error)? errorMessageBuilder;

  final WidgetBuilder? loadingBuilder;

  /// 自定义错误视图，优先于 [errorMessageBuilder]。
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  )?
  errorBuilder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      // 下拉刷新 / 手动 reload 期间保留旧数据，避免闪烁。
      skipLoadingOnReload: true,
      loading: () =>
          loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          errorBuilder?.call(context, error, stackTrace) ??
          _ErrorView(
            message:
                errorMessageBuilder?.call(error) ??
                AppLocalizations.of(context)!.loadFailed,
            onRetry: onRetry,
          ),
      data: data,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: context.colors.destructive,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
