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
/// - autoDispose：离开详情页即释放，重新进入按 ID 重新加载。
final userDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<UserDetailViewModel, UserDetailUiState, int>(
      UserDetailViewModel.new,
    );

class UserDetailViewModel extends AsyncNotifier<UserDetailUiState> {
  UserDetailViewModel(this.userId);

  /// 路由参数：目标用户 ID。
  final int userId;

  UserRepository get _repository => ref.read(userRepositoryProvider);

  @override
  Future<UserDetailUiState> build() async {
    try {
      // 并行请求详情与收藏状态（Dart 3 record .wait 扩展）。
      final (user, favorites) = await (
        _repository.getUser(userId),
        _repository.getFavoriteIds(),
      ).wait;
      return UserDetailUiState(
        user: user,
        isFavorite: favorites.contains(userId),
      );
    } on ParallelWaitError catch (error) {
      // .wait 会把子 Future 的异常包装成 ParallelWaitError；
      // 解包还原原始异常，维持 Repository 的 AppException 契约。
      final asyncError = error.errors.$1 ?? error.errors.$2;
      if (asyncError == null) {
        rethrow;
      }
      Error.throwWithStackTrace(asyncError.error, asyncError.stackTrace);
    }
  }

  bool _favoriteWriteInFlight = false;

  /// 切换收藏：乐观更新（先改 UI，持久化失败再回滚）。
  ///
  /// - 写入进行中忽略重复点击，防止并发写入互相覆盖 / 回滚；
  /// - 成功后以 Repository 返回的收藏集合为准（权威状态）；
  /// - autoDispose 下离开页面后写入完成，不更新已销毁的状态。
  Future<void> toggleFavorite() async {
    final current = state.value;
    if (current == null || _favoriteWriteInFlight) {
      return;
    }
    _favoriteWriteInFlight = true;
    state = AsyncData(current.copyWith(isFavorite: !current.isFavorite));
    try {
      final favorites = await _repository.toggleFavorite(current.user.id);
      if (ref.mounted) {
        state = AsyncData(
          current.copyWith(isFavorite: favorites.contains(userId)),
        );
      }
    } on Exception {
      // 持久化失败：回滚到更新前的状态。
      if (ref.mounted) {
        state = AsyncData(current);
      }
    } finally {
      _favoriteWriteInFlight = false;
    }
  }
}
