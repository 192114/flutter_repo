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

  Future<void>? _refreshRequest;

  /// 首次构建：从 Repository 加载用户列表。
  @override
  Future<UserListUiState> build() async {
    final users = await _repository.getUsers();
    return UserListUiState(users: users);
  }

  /// 下拉刷新：重新拉取数据。
  ///
  /// - 复用进行中的请求（重叠刷新不重复发网络请求）；
  /// - 成功后合并「等待期间」用户输入的最新搜索词，而非覆盖；
  /// - 失败时若已有数据则保留现状（下拉刷新失败不清空列表）。
  Future<void> refresh() => _refreshRequest ??= _refresh();

  Future<void> _refresh() async {
    try {
      final users = await _repository.getUsers();
      if (!ref.mounted) {
        return;
      }
      // Riverpod 3.x：`value` 即旧版的 valueOrNull（可空，不抛错）。
      // 此时读到的是等待期间 onQueryChanged 写入的最新搜索词。
      state = AsyncData(
        UserListUiState(users: users, query: state.value?.query ?? ''),
      );
    } on Exception catch (error, stackTrace) {
      if (!ref.mounted) {
        return;
      }
      if (state.value == null) {
        // 无数据可保留（如错误页重试再次失败）：维持错误态。
        state = AsyncError(error, stackTrace);
      }
    } finally {
      _refreshRequest = null;
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
