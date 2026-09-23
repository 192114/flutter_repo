// ViewModel 单元测试：通过 override Repository 为 Fake / 可控替身，
// 不启动 UI、不请求网络即可覆盖全部业务分支。

import 'package:flutter_repo/data/exceptions/app_exception.dart';
import 'package:flutter_repo/data/models/user.dart';
import 'package:flutter_repo/data/repositories/user_repository.dart';
import 'package:flutter_repo/ui/features/user/view_model/user_list_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/controllable_user_repository.dart';
import '../../../../fakes/fake_user_repository.dart';

void main() {
  group('UserListViewModel', () {
    late FakeUserRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = FakeUserRepository();
      container = ProviderContainer(
        overrides: [userRepositoryProvider.overrideWithValue(fakeRepository)],
      );
    });

    tearDown(() => container.dispose());

    test('初始 build 加载全部用户', () async {
      final state = await container.read(userListViewModelProvider.future);

      expect(state.users, hasLength(3));
      expect(state.query, '');
      expect(state.filteredUsers, hasLength(3));
    });

    test('onQueryChanged 按 name 过滤（单向数据流）', () async {
      // 1. 等待初始数据就绪。
      await container.read(userListViewModelProvider.future);

      // 2. 用户输入事件 → ViewModel 方法。
      container
          .read(userListViewModelProvider.notifier)
          .onQueryChanged('leanne');

      // 3. 新状态 → 派生数据由纯函数计算。
      final state = container.read(userListViewModelProvider).requireValue;
      expect(state.query, 'leanne');
      expect(state.filteredUsers, hasLength(1));
      expect(state.filteredUsers.first.name, 'Leanne Graham');
      // 原始数据不被破坏：不可变状态只增不改。
      expect(state.users, hasLength(3));
    });

    test('refresh 失败但已有数据：保留数据与搜索词（不清空列表）', () async {
      await container.read(userListViewModelProvider.future);
      container
          .read(userListViewModelProvider.notifier)
          .onQueryChanged('leanne');

      fakeRepository.errorToThrow = const NetworkException();
      await container.read(userListViewModelProvider.notifier).refresh();

      final state = container.read(userListViewModelProvider).requireValue;
      expect(state.users, hasLength(3));
      expect(state.query, 'leanne');
      expect(state.filteredUsers, hasLength(1));
    });

    test('refresh 成功后数据更新且保留搜索词', () async {
      await container.read(userListViewModelProvider.future);
      container
          .read(userListViewModelProvider.notifier)
          .onQueryChanged('ervin');

      await container.read(userListViewModelProvider.notifier).refresh();

      final state = container.read(userListViewModelProvider).requireValue;
      expect(state.users, hasLength(3));
      expect(state.query, 'ervin');
      expect(state.filteredUsers.single.name, 'Ervin Howell');
    });
  });

  group('UserListViewModel（可控时序）', () {
    late ControllableUserRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = ControllableUserRepository();
      container = ProviderContainer(
        overrides: [userRepositoryProvider.overrideWithValue(repository)],
      );
    });

    tearDown(() => container.dispose());

    test('首次加载失败进入错误态，重试成功后恢复', () async {
      final subscription = container.listen(
        userListViewModelProvider,
        (_, _) {},
      );
      container.read(userListViewModelProvider.notifier);
      repository.listRequests.last.completeError(const NetworkException());
      await container.pump();

      final errorState = container.read(userListViewModelProvider);
      expect(errorState.hasError, isTrue);
      expect(errorState.error, isA<NetworkException>());

      final retry = container
          .read(userListViewModelProvider.notifier)
          .refresh();
      repository.listRequests.last.complete(const [User(id: 1, name: 'Alice')]);
      await retry;

      final state = container.read(userListViewModelProvider).requireValue;
      expect(state.users, hasLength(1));
      expect(state.query, '');

      addTearDown(subscription.close);
    });

    test('无数据时重试再次失败：维持错误态', () async {
      final subscription = container.listen(
        userListViewModelProvider,
        (_, _) {},
      );
      container.read(userListViewModelProvider.notifier);
      repository.listRequests.last.completeError(const NetworkException());
      await container.pump();
      expect(container.read(userListViewModelProvider).hasError, isTrue);

      final retry = container
          .read(userListViewModelProvider.notifier)
          .refresh();
      repository.listRequests.last.completeError(const NetworkException());
      await retry;

      expect(container.read(userListViewModelProvider).hasError, isTrue);

      addTearDown(subscription.close);
    });

    test('刷新等待期间的搜索输入不被响应覆盖', () async {
      final notifier = container.read(userListViewModelProvider.notifier);
      repository.listRequests.last.complete(const [User(id: 1, name: 'Alice')]);
      await container.read(userListViewModelProvider.future);

      notifier.onQueryChanged('old');

      final refresh = notifier.refresh();
      // 等待响应期间用户继续输入。
      notifier.onQueryChanged('new');
      repository.listRequests.last.complete(const [User(id: 1, name: 'Alice')]);
      await refresh;

      expect(
        container.read(userListViewModelProvider).requireValue.query,
        'new',
      );
    });

    test('重叠刷新复用同一请求，不重复拉取', () async {
      final notifier = container.read(userListViewModelProvider.notifier);
      repository.listRequests.last.complete(const [User(id: 1, name: 'Alice')]);
      await container.read(userListViewModelProvider.future);

      final first = notifier.refresh();
      final second = notifier.refresh();
      // 初始加载 1 次 + 刷新 1 次：第二次 refresh 复用进行中的请求。
      expect(repository.listRequests, hasLength(2));

      repository.listRequests.last.complete(const [User(id: 1, name: 'Alice')]);
      await first;
      await second;
    });
  });
}
