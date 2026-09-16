import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  /// ViewModel 暴露的异步状态。
  final AsyncValue<T> value;

  /// 数据就绪时的渲染回调。
  final Widget Function(T data) data;

  /// 错误重试回调（为空则不显示重试按钮）。
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      // 下拉刷新 / 手动 reload 期间保留旧数据，避免闪烁。
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: error.toString(),
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
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
