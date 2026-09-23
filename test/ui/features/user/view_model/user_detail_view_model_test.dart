// 详情 ViewModel 单元测试：异常契约、乐观更新并发、autoDispose 生命周期。

import 'package:flutter_repo/data/exceptions/app_exception.dart';
import 'package:flutter_repo/data/repositories/user_repository.dart';
import 'package:flutter_repo/ui/features/user/view_model/user_detail_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/controllable_user_repository.dart';

void main() {
  late ControllableUserRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = ControllableUserRepository();
    container = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  // autoDispose provider 需要显式订阅保持存活。
  ProviderSubscription<Object?> subscribe() =>
      container.listen(userDetailViewModelProvider(1), (_, _) {});

  group('UserDetailViewModel.build', () {
    test('详情加载失败：状态持有原始异常，不被 ParallelWaitError 包装', () async {
      repository.detailError = const NotFoundException();
      final subscription = subscribe();

      await container.pump();

      final state = container.read(userDetailViewModelProvider(1));
      expect(state.hasError, isTrue);
      expect(state.error, isA<NotFoundException>());

      addTearDown(subscription.close);
    });

    test('收藏状态加载失败：状态持有原始 CacheException', () async {
      repository.favoritesError = const CacheException();
      final subscription = subscribe();

      await container.pump();

      final state = container.read(userDetailViewModelProvider(1));
      expect(state.hasError, isTrue);
      expect(state.error, isA<CacheException>());

      addTearDown(subscription.close);
    });
  });

  group('UserDetailViewModel.toggleFavorite', () {
    test('成功：以 Repository 返回的收藏集合为准（权威状态）', () async {
      final subscription = subscribe();
      await container.read(userDetailViewModelProvider(1).future);
      expect(
        container.read(userDetailViewModelProvider(1)).requireValue.isFavorite,
        isFalse,
      );

      final toggle = container
          .read(userDetailViewModelProvider(1).notifier)
          .toggleFavorite();
      // 乐观更新先行。
      expect(
        container.read(userDetailViewModelProvider(1)).requireValue.isFavorite,
        isTrue,
      );
      // Repository 返回不含该用户的集合：权威状态覆盖乐观值。
      repository.toggleRequests.single.complete(const <int>{});
      await toggle;

      expect(
        container.read(userDetailViewModelProvider(1)).requireValue.isFavorite,
        isFalse,
      );

      addTearDown(subscription.close);
    });

    test('失败：回滚到切换前状态', () async {
      final subscription = subscribe();
      await container.read(userDetailViewModelProvider(1).future);

      final toggle = container
          .read(userDetailViewModelProvider(1).notifier)
          .toggleFavorite();
      repository.toggleRequests.single.completeError(const CacheException());
      await toggle;

      expect(
        container.read(userDetailViewModelProvider(1)).requireValue.isFavorite,
        isFalse,
      );

      addTearDown(subscription.close);
    });

    test('写入进行中忽略重复点击（不产生并发写入）', () async {
      final subscription = subscribe();
      await container.read(userDetailViewModelProvider(1).future);

      final first = container
          .read(userDetailViewModelProvider(1).notifier)
          .toggleFavorite();
      final second = container
          .read(userDetailViewModelProvider(1).notifier)
          .toggleFavorite();
      expect(repository.toggleRequests, hasLength(1));

      repository.toggleRequests.single.complete(const <int>{1});
      await first;
      await second;

      expect(
        container.read(userDetailViewModelProvider(1)).requireValue.isFavorite,
        isTrue,
      );

      addTearDown(subscription.close);
    });

    test('写入期间离开页面：provider 释放且不抛 StateError', () async {
      final subscription = subscribe();
      await container.read(userDetailViewModelProvider(1).future);

      final pending = container
          .read(userDetailViewModelProvider(1).notifier)
          .toggleFavorite();
      subscription.close();
      await container.pump();
      expect(container.exists(userDetailViewModelProvider(1)), isFalse);

      // 写入在页面销毁后完成（失败）：不应触碰已销毁的状态。
      repository.toggleRequests.single.completeError(const CacheException());
      await pending;
    });
  });
}
