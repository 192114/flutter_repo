import 'package:flutter_repo/data/exceptions/app_exception.dart';
import 'package:flutter_repo/data/repositories/user_repository.dart';
import 'package:flutter_repo/ui/features/user/view_model/user_list_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_user_repository.dart';

/// ViewModel 单元测试：通过 override Repository 为 Fake，
/// 不启动 UI、不请求网络即可覆盖全部业务分支。
void main() {
  group('UserListViewModel', () {
    late FakeUserRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = FakeUserRepository();
      container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(fakeRepository),
        ],
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

    test('refresh 失败时进入错误状态', () async {
      await container.read(userListViewModelProvider.future);

      fakeRepository.errorToThrow = const NetworkException();
      await container.read(userListViewModelProvider.notifier).refresh();

      final asyncState = container.read(userListViewModelProvider);
      expect(asyncState.hasError, isTrue);
      expect(asyncState.error, isA<NetworkException>());
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
}
