import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/theme_mode_menu.dart';

/// 组件库索引页：App 全部共享组件与 Design Token 的演示入口。
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries =
        <
          ({
            Key key,
            IconData icon,
            String title,
            String desc,
            String routeName,
          })
        >[
          (
            key: const Key('gallery-entry-feedback'),
            icon: Icons.chat_bubble_outline_rounded,
            title: '反馈组件',
            desc: 'Toast 轻提示与 Dialog 弹窗',
            routeName: AppRoute.galleryFeedback.name,
          ),
          (
            key: const Key('gallery-entry-dropdown'),
            icon: Icons.filter_list_rounded,
            title: '下拉菜单',
            desc: 'Vant 风格顶部菜单栏，排序与筛选',
            routeName: AppRoute.galleryDropdown.name,
          ),
          (
            key: const Key('gallery-entry-async'),
            icon: Icons.sync_rounded,
            title: '异步状态',
            desc: 'AsyncValueView 加载 / 错误 / 成功三态',
            routeName: AppRoute.galleryAsync.name,
          ),
          (
            key: const Key('gallery-entry-tokens'),
            icon: Icons.palette_outlined,
            title: 'Design Token',
            desc: '颜色、圆角与间距规范速查',
            routeName: AppRoute.galleryTokens.name,
          ),
          (
            key: const Key('gallery-entry-form'),
            icon: Icons.edit_note_rounded,
            title: '表单组件',
            desc: '按钮、输入、选择控件与各类选择器',
            routeName: AppRoute.galleryForm.name,
          ),
          (
            key: const Key('gallery-entry-tag'),
            icon: Icons.label_outline_rounded,
            title: '标签',
            desc: '实心 / 空心、可删除与三档尺寸',
            routeName: AppRoute.galleryTag.name,
          ),
          (
            key: const Key('gallery-entry-upload'),
            icon: Icons.cloud_upload_outlined,
            title: '图片上传',
            desc: '九宫格上传、进度状态与图片剪裁',
            routeName: AppRoute.galleryUpload.name,
          ),
          (
            key: const Key('gallery-entry-empty'),
            icon: Icons.inbox_outlined,
            title: '空状态',
            desc: '自定义图标、标题、描述与底部操作',
            routeName: AppRoute.galleryEmpty.name,
          ),
        ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('组件库'),
        actions: const [ThemeModeMenu()],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth > 720 ? 720 : double.infinity,
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _GalleryEntryCard(
                  key: entry.key,
                  icon: entry.icon,
                  title: entry.title,
                  description: entry.desc,
                  onTap: () => context.pushNamed(entry.routeName),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryEntryCard extends StatelessWidget {
  const _GalleryEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: AppRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: colors.accentForeground),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.cardForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
