import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_ext.dart';

class AppEmpty extends StatelessWidget {
  const AppEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.compact = false,
  });

  final Widget icon;
  final String title;
  final String? description;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final iconSize = compact ? 40.0 : 96.0;
    final textAlign = compact ? TextAlign.start : TextAlign.center;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: textTheme.titleMedium?.copyWith(
            color: colors.foreground,
            fontSize: compact ? 16 : 18,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (description case final description?
            when description.isNotEmpty) ...[
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            description,
            textAlign: textAlign,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.mutedForeground,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
        if (action case final action?) ...[
          SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: action,
          ),
        ],
      ],
    );
    final illustration = SizedBox.square(
      dimension: iconSize,
      child: IconTheme.merge(
        data: IconThemeData(size: iconSize, color: colors.mutedForeground),
        child: icon,
      ),
    );

    return Padding(
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xxl),
      child: compact
          ? Row(
              children: [
                illustration,
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: content),
              ],
            )
          : Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    illustration,
                    const SizedBox(height: AppSpacing.xxl),
                    content,
                  ],
                ),
              ),
            ),
    );
  }
}
