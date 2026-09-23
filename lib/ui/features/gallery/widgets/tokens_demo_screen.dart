import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_ext.dart';
import 'gallery_section.dart';

/// Design Token 速查页：颜色语义、圆角与间距阶梯。
class TokensDemoScreen extends StatelessWidget {
  const TokensDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final colorTokens = <(String, Color)>[
      ('background', colors.background),
      ('foreground', colors.foreground),
      ('card', colors.card),
      ('cardForeground', colors.cardForeground),
      ('primary', colors.primary),
      ('primaryForeground', colors.primaryForeground),
      ('secondary', colors.secondary),
      ('secondaryForeground', colors.secondaryForeground),
      ('muted', colors.muted),
      ('mutedForeground', colors.mutedForeground),
      ('accent', colors.accent),
      ('accentForeground', colors.accentForeground),
      ('destructive', colors.destructive),
      ('destructiveForeground', colors.destructiveForeground),
      ('border', colors.border),
      ('input', colors.input),
      ('ring', colors.ring),
      ('success', colors.success),
      ('warning', colors.warning),
      ('info', colors.info),
    ];

    const radiusTokens = <(String, double)>[
      ('xs', AppRadius.xs),
      ('sm', AppRadius.sm),
      ('md', AppRadius.md),
      ('lg', AppRadius.lg),
      ('xl', AppRadius.xl),
    ];

    const spacingTokens = <(String, double)>[
      ('xs', AppSpacing.xs),
      ('sm', AppSpacing.sm),
      ('md', AppSpacing.md),
      ('lg', AppSpacing.lg),
      ('xl', AppSpacing.xl),
      ('xxl', AppSpacing.xxl),
      ('xxxl', AppSpacing.xxxl),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Design Token')),
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
                  title: '颜色',
                  description: 'AppColors 语义色板，随明暗主题自动换肤。',
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final (name, color) in colorTokens)
                        _ColorSwatch(name: name, color: color),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GallerySection(
                  title: '圆角',
                  description: 'AppRadius 圆角阶梯（4px 递增）。',
                  child: Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      for (final (name, value) in radiusTokens)
                        _RadiusSample(name: name, radius: value),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GallerySection(
                  title: '间距',
                  description: 'AppSpacing 间距阶梯（4px 栅格）。',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (name, value) in spacingTokens)
                        _SpacingSample(name: name, width: value),
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

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hex =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    return SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: colors.border),
              borderRadius: AppRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.cardForeground),
          ),
          Text(
            hex,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _RadiusSample extends StatelessWidget {
  const _RadiusSample({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.accent,
            border: Border.all(color: colors.accentForeground),
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$name · ${radius.toInt()}',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.mutedForeground),
        ),
      ],
    );
  }
}

class _SpacingSample extends StatelessWidget {
  const _SpacingSample({required this.name, required this.width});

  final String name;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              '$name · ${width.toInt()}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.mutedForeground),
            ),
          ),
          Container(
            width: width,
            height: 12,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: AppRadius.circular(AppRadius.xs),
            ),
          ),
        ],
      ),
    );
  }
}
