import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/theme_mode_menu.dart';
import '../view_model/user_list_view_model.dart';
import 'user_card.dart';

/// 用户列表页（Dumb Widget）。
///
/// 职责仅限两件事：
/// 1. watch ViewModel 状态并渲染（渲染逻辑纯函数化）；
/// 2. 把用户交互转发给 ViewModel，或执行纯导航副作用。
///
/// 严禁出现：数据请求、状态修改、业务判断 —— 全部下沉到 ViewModel。
class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch 状态：状态变化自动重建本 Widget。
    final asyncState = ref.watch(userListViewModelProvider);
    // read notifier：方法引用稳定，无需监听。
    final viewModel = ref.read(userListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('用户列表'),
        actions: [
          IconButton(
            tooltip: '组件库',
            onPressed: () => context.pushNamed(AppRoute.gallery.name),
            icon: const Icon(Icons.widgets_outlined),
          ),
          const ThemeModeMenu(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              // 单向数据流：输入 → ViewModel.onQueryChanged → 新状态 → 重建。
              onChanged: viewModel.onQueryChanged,
              decoration: const InputDecoration(
                hintText: '搜索姓名或邮箱',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: asyncState,
              onRetry: viewModel.refresh,
              data: (state) =>
                  _UserListView(state: state, onRefresh: viewModel.refresh),
            ),
          ),
        ],
      ),
    );
  }
}

/// 列表区域：接收不可变状态渲染，无任何副作用。
class _UserListView extends StatelessWidget {
  const _UserListView({required this.state, required this.onRefresh});

  final UserListUiState state;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final users = state.filteredUsers;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: users.isEmpty
          ? CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.users.isEmpty
                              ? '暂无用户'
                              : '没有匹配「${state.query}」的用户',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.users.isEmpty ? '下拉刷新试试' : '试试其他姓名或邮箱，或下拉刷新',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              // 保证内容不足一屏时仍可下拉刷新。
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = users[index];
                return UserCard(
                  user: user,
                  // 页面跳转属于 View 副作用，允许在 View 层执行；
                  // 只传 ID，详情页自行加载数据（深链接友好）。
                  onTap: () => context.pushNamed(
                    AppRoute.userDetail.name,
                    pathParameters: {'id': user.id.toString()},
                  ),
                );
              },
            ),
    );
  }
}
