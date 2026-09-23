import 'package:flutter/material.dart';

import '../../../../data/models/user.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_ext.dart';

/// 用户卡片（纯展示组件，零业务逻辑）。
///
/// 数据进（[user]）、事件出（[onTap]）：
/// 不持有状态、不访问 Provider、不感知 Repository，
/// 可以独立预览、独立测试、任意复用。
class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user, this.onTap});

  final User user;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 颜色统一走语义 token（随主题切换），不直接消费 ColorScheme。
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colors.accent,
                foregroundColor: colors.accentForeground,
                child: Text(
                  user.name.isEmpty ? '?' : user.name.characters.first,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.username} · ${user.email}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colors.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
