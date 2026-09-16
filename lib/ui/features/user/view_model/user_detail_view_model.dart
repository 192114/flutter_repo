import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/user.dart';
import '../../../../data/repositories/user_repository.dart';

part 'user_detail_view_model.freezed.dart';

/// 用户详情页 UI 状态（不可变）。
@freezed
abstract class UserDetailUiState with _$UserDetailUiState {
  const factory UserDetailUiState({
    required User user,
    @Default(false) bool isFavorite,
  }) = _UserDetailUiState;
}

/// 用户详情 ViewModel（Riverpod 3.x family 写法）。
///
/// - family 参数 [userId] 通过构造函数注入；
/// - 同一 userId 的多个观察者共享同一状态实例；
/// - 打开不同用户的详情页时，参数变化自动重建。
final userDetailViewModelProvider =
    AsyncNotifierProvider.family<UserDetailViewModel, UserDetailUiState, int>(
  UserDetailViewModel.new,
);

class UserDetailViewModel extends AsyncNotifier<UserDetailUiState> {
  UserDetailViewModel(this.userId);

  /// 路由参数：目标用户 ID。
  final int userId;

  UserRepository get _repository => ref.read(userRepositoryProvider);

  @override
  Future<UserDetailUiState> build() async {
    // 并行请求详情与收藏状态（Dart 3 record .wait 扩展）。
    final (user, favorites) = await (
      _repository.getUser(userId),
      _repository.getFavoriteIds(),
    ).wait;
    return UserDetailUiState(
      user: user,
      isFavorite: favorites.contains(userId),
    );
  }

  /// 切换收藏：乐观更新（先改 UI，持久化失败再回滚）。
  Future<void> toggleFavorite() async {
    final current = state.value;
    if (current == null) {
      return;
    }

    state = AsyncData(current.copyWith(isFavorite: !current.isFavorite));
    try {
      await _repository.toggleFavorite(current.user.id);
    } on Exception {
      // 持久化失败：回滚到更新前的状态。
      state = AsyncData(current);
    }
  }
}
