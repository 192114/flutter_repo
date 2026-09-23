import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_empty_illustration.dart';
import '../../../core/widgets/app_toast.dart';
import 'gallery_section.dart';

class EmptyDemoScreen extends StatefulWidget {
  const EmptyDemoScreen({super.key});

  @override
  State<EmptyDemoScreen> createState() => _EmptyDemoScreenState();
}

class _EmptyDemoScreenState extends State<EmptyDemoScreen> {
  bool _showDescription = true;
  bool _showAction = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Empty 空状态')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                '空状态组件演示',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '图标与标题必填，描述和底部操作可选。无内容不等于加载中或加载失败。',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.mutedForeground),
              ),
              const SizedBox(height: AppSpacing.xxl),
              GallerySection(
                title: '01 默认空状态',
                description: '轻量插画与明确的下一步操作。',
                child: AppEmpty(
                  icon: const AppEmptyIllustration(
                    type: AppEmptyIllustrationType.content,
                  ),
                  title: '这里还没有内容',
                  description: '从第一条记录开始\n把想法和重要的事留在这里',
                  action: AppButton(
                    label: '创建内容',
                    icon: Icons.add,
                    onPressed: () => AppToast.success(context, '创建内容回调已触发'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GallerySection(
                title: '02 搜索无结果',
                description: '使用次要按钮提供恢复路径。',
                child: AppEmpty(
                  icon: const AppEmptyIllustration(
                    type: AppEmptyIllustrationType.search,
                  ),
                  title: '没有找到相关结果',
                  description: '试试其他关键词\n或清除筛选条件后重新搜索',
                  action: AppButton(
                    label: '清除筛选',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => AppToast.success(context, '清除筛选回调已触发'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GallerySection(
                title: '03 暂无收藏',
                description: '操作区域也可以使用文字按钮。',
                child: AppEmpty(
                  icon: const AppEmptyIllustration(
                    type: AppEmptyIllustrationType.favorites,
                  ),
                  title: '还没有收藏',
                  description: '遇到喜欢的内容，点一下收藏\n下次就能在这里找到它',
                  action: Material(
                    type: MaterialType.transparency,
                    child: TextButton(
                      onPressed: () => AppToast.success(context, '去发现回调已触发'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('去发现'),
                          SizedBox(width: AppSpacing.sm),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GallerySection(
                title: '04 紧凑模式',
                description: '适用于卡片、弹层与局部区域。',
                child: Column(
                  children: [
                    AppEmpty(
                      compact: true,
                      icon: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: AppRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.inbox_outlined,
                          size: 24,
                          color: colors.primary,
                        ),
                      ),
                      title: '暂无数据',
                      description: '内容将在添加后显示',
                    ),
                    const AppEmpty(
                      compact: true,
                      icon: Icon(Icons.inbox_outlined, size: 24),
                      title: '暂无记录',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GallerySection(
                title: '05 自定义插槽',
                description: '传入任意图标 Widget，底部可放一个或多个按钮。',
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Text('显示描述')),
                          Semantics(
                            label: '显示描述',
                            child: Switch(
                              key: const Key('empty-toggle-description'),
                              value: _showDescription,
                              onChanged: (value) =>
                                  setState(() => _showDescription = value),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Expanded(child: Text('显示底部操作')),
                          Semantics(
                            label: '显示底部操作',
                            child: Switch(
                              key: const Key('empty-toggle-action'),
                              value: _showAction,
                              onChanged: (value) =>
                                  setState(() => _showAction = value),
                            ),
                          ),
                        ],
                      ),
                      AppEmpty(
                        key: const Key('empty-custom'),
                        icon: Icon(
                          Icons.auto_awesome_outlined,
                          color: colors.primary,
                        ),
                        title: '你的自定义标题',
                        description: _showDescription
                            ? '描述可以省略，操作区域也可以自由组合。'
                            : null,
                        action: _showAction
                            ? Wrap(
                                alignment: WrapAlignment.center,
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  AppButton(
                                    label: '主要操作',
                                    onPressed: () =>
                                        AppToast.success(context, '主要操作回调已触发'),
                                  ),
                                  AppButton(
                                    label: '次要操作',
                                    variant: AppButtonVariant.secondary,
                                    onPressed: () =>
                                        AppToast.success(context, '次要操作回调已触发'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Empty · Light', group: 'Feedback', size: Size(390, 844))
Widget emptyLightPreview() => LookupBoundary(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    theme: AppTheme.light,
    home: const EmptyDemoScreen(),
  ),
);

@Preview(name: 'Empty · Dark', group: 'Feedback', size: Size(390, 844))
Widget emptyDarkPreview() => LookupBoundary(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    theme: AppTheme.dark,
    home: const EmptyDemoScreen(),
  ),
);
