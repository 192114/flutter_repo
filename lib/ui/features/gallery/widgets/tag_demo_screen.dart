import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_tag.dart';
import 'gallery_section.dart';

/// 标签组件演示页：实心 / 空心 / 可删除与三档尺寸的真实效果。
class TagDemoScreen extends StatefulWidget {
  const TagDemoScreen({super.key});

  @override
  State<TagDemoScreen> createState() => _TagDemoScreenState();
}

class _TagDemoScreenState extends State<TagDemoScreen> {
  final _closableTags = ['苏州', '园林', '评弹', '苏绣'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('标签')),
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
                  '标签组件演示',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '实心 / 空心两种形态、五种语义色与三档尺寸，支持尾部关闭。',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.mutedForeground),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const GallerySection(
                  title: '实心',
                  description: '填充底色，用于强调状态或分类。',
                  child: Wrap(
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
                ),
                const SizedBox(height: AppSpacing.lg),
                const GallerySection(
                  title: '空心',
                  description: '透明底加语义色描边，视觉层级更弱。',
                  child: Wrap(
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
                ),
                const SizedBox(height: AppSpacing.lg),
                GallerySection(
                  title: '可删除',
                  description: '尾部 × 关闭，点击即从列表移除。',
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final (index, tag) in _closableTags.indexed)
                        AppTag(
                          key: Key('closable-tag-$tag'),
                          label: tag,
                          color: index.isEven
                              ? AppTagColor.primary
                              : AppTagColor.normal,
                          variant: index.isEven
                              ? AppTagVariant.filled
                              : AppTagVariant.outlined,
                          onClose: () =>
                              setState(() => _closableTags.remove(tag)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const GallerySection(
                  title: '尺寸',
                  description: '小 24 / 中 28 / 大 32，字号与图标随档缩放。',
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppTag(label: '小号', size: AppTagSize.small),
                      AppTag(label: '中号'),
                      AppTag(label: '大号', size: AppTagSize.large),
                      AppTag(
                        label: '大号描边',
                        variant: AppTagVariant.outlined,
                        size: AppTagSize.large,
                        onClose: _noop,
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

void _noop() {}
