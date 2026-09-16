import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_value_view.dart';
import '../view_model/user_detail_view_model.dart';

/// 用户详情页（Dumb Widget）。
///
/// 只接收路由参数 [userId]，数据由 UserDetailViewModel 加载；
/// Widget 自身零状态、零业务逻辑。
class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = userDetailViewModelProvider(userId);
    final asyncState = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('用户详情')),
      body: AsyncValueView(
        value: asyncState,
        data: (state) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(
              state: state,
              onToggleFavorite: viewModel.toggleFavorite,
            ),
            const SizedBox(height: 16),
            _InfoTile(icon: Icons.badge, label: '用户名', value: state.user.username),
            _InfoTile(icon: Icons.alternate_email, label: '邮箱', value: state.user.email),
            _InfoTile(icon: Icons.phone, label: '电话', value: state.user.phone),
            _InfoTile(icon: Icons.language, label: '网站', value: state.user.website),
            _InfoTile(
              icon: Icons.business,
              label: '公司',
              value: state.user.company?.name ?? '—',
            ),
          ],
        ),
      ),
    );
  }
}

/// 头像 + 姓名 + 收藏按钮。
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.state, required this.onToggleFavorite});

  final UserDetailUiState state;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Text(
            state.user.name.isEmpty ? '?' : state.user.name.characters.first,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.user.name,
                style: textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (state.user.company?.name.isNotEmpty ?? false)
                Text(
                  state.user.company!.name,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          // 交互事件全部转发给 ViewModel。
          onPressed: onToggleFavorite,
          icon: Icon(
            state.isFavorite ? Icons.favorite : Icons.favorite_border,
          ),
          label: Text(state.isFavorite ? '已收藏' : '收藏'),
        ),
      ],
    );
  }
}

/// 信息行（纯展示）。
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(label, style: textTheme.labelLarge),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
