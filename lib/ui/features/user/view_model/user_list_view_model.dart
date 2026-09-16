import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/user.dart';
import '../../../../data/repositories/user_repository.dart';

part 'user_list_view_model.freezed.dart';

/// 用户列表页 UI 状态（不可变）。
///
/// 「原始数据」与「派生数据」分离：
/// [query] 只是输入，[filteredUsers] 是纯函数计算结果，
/// 同一状态必然渲染出同一 UI —— 单向数据流的基础。
@freezed
abstract class UserListUiState with _$UserListUiState {
  const factory UserListUiState({
    @Default(<User>[]) List<User> users,
    @Default('') String query,
  }) = _UserListUiState;

  const UserListUiState._();

  /// 根据搜索词过滤后的列表（按 name / email 模糊匹配）。
  List<User> get filteredUsers {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) {
      return users;
    }
    return users
        .where(
          (user) =>
              user.name.toLowerCase().contains(keyword) ||
              user.email.toLowerCase().contains(keyword),
        )
        .toList();
  }
}

/// 用户列表 ViewModel。
///
/// MVVM 职责约定：
/// - 持有并「唯一」负责修改 [UserListUiState]；
/// - View 只调用这里的公开方法表达意图，从不直接改状态；
/// - 数据获取全部委托给 [UserRepository]，ViewModel 不感知 Dio / SharedPreferences。
final userListViewModelProvider =
    AsyncNotifierProvider<UserListViewModel, UserListUiState>(
  UserListViewModel.new,
);

class UserListViewModel extends AsyncNotifier<UserListUiState> {
  UserRepository get _repository => ref.read(userRepositoryProvider);

  /// 首次构建：从 Repository 加载用户列表。
  @override
  Future<UserListUiState> build() async {
    final users = await _repository.getUsers();
    return UserListUiState(users: users);
  }

  /// 下拉刷新：重新拉取数据，但保留用户已输入的搜索词。
  Future<void> refresh() async {
    // Riverpod 3.x：`value` 即旧版的 valueOrNull（可空，不抛错）。
    final previousQuery = state.value?.query ?? '';
    try {
      final users = await _repository.getUsers();
      state = AsyncData(UserListUiState(users: users, query: previousQuery));
    } on Exception catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// 搜索词变化（由 View 的 TextField.onChanged 触发）。
  void onQueryChanged(String query) {
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncData(current.copyWith(query: query));
  }
}
