import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/async_value_view.dart';
import 'gallery_section.dart';

/// AsyncValueView 演示页：手动切换 加载 / 错误 / 成功 三态。
class AsyncValueDemoScreen extends StatefulWidget {
  const AsyncValueDemoScreen({super.key});

  @override
  State<AsyncValueDemoScreen> createState() => _AsyncValueDemoScreenState();
}

class _AsyncValueDemoScreenState extends State<AsyncValueDemoScreen> {
  /// 0 = 加载中，1 = 失败，2 = 成功。
  var _index = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final value = switch (_index) {
      0 => const AsyncValue<String>.loading(),
      1 => AsyncValue<String>.error('网络请求失败（模拟）', StackTrace.empty),
      _ => const AsyncValue<String>.data('共 42 条记录，耗时 128ms'),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('异步状态')),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 720 ? 720 : double.infinity,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                GallerySection(
                  title: '三态切换',
                  description:
                      'AsyncValueView 统一渲染 Loading / Error / Data，'
                      '错误态可通过重试按钮恢复。',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('加载中')),
                          ButtonSegment(value: 1, label: Text('失败')),
                          ButtonSegment(value: 2, label: Text('成功')),
                        ],
                        selected: {_index},
                        onSelectionChanged: (selection) =>
                            setState(() => _index = selection.first),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 240,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.border),
                            borderRadius: AppRadius.circular(AppRadius.md),
                          ),
                          child: AsyncValueView<String>(
                            value: value,
                            onRetry: () => setState(() => _index = 2),
                            data: (data) => Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 48,
                                    color: colors.success,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text('数据加载成功'),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    data,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colors.mutedForeground,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
