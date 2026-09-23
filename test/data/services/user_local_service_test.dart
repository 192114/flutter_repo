// 本地存储服务边界测试：写入失败、历史数据损坏降级。

import 'package:flutter_repo/data/exceptions/app_exception.dart';
import 'package:flutter_repo/data/services/user_local_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../fakes/failing_shared_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 每个用例重置单例并挂载可控 store，再取全新实例。
  Future<SharedPreferences> prefsFor({
    SharedPreferencesStorePlatform? store,
    Map<String, Object> initial = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initial);
    if (store != null) {
      SharedPreferencesStorePlatform.instance = store;
    }
    return SharedPreferences.getInstance();
  }

  group('UserLocalService', () {
    test('正常读写与切换收藏', () async {
      final service = UserLocalService(await prefsFor());

      expect(service.readFavoriteIds(), isEmpty);
      expect(await service.toggleFavorite(1), {1});
      expect(service.readFavoriteIds(), {1});
      expect(await service.toggleFavorite(1), isEmpty);
    });

    test('落盘失败：上抛 CacheException 且读回磁盘真实状态', () async {
      final service = UserLocalService(
        await prefsFor(store: FailingWriteStore()),
      );

      await expectLater(
        service.toggleFavorite(1),
        throwsA(isA<CacheException>()),
      );
      // 插件写入失败前已更新内存缓存，reload 后应与磁盘一致（空）。
      expect(service.readFavoriteIds(), isEmpty);
    });

    test('历史数据类型异常：降级为空集合（不抛 TypeError）', () async {
      final service = UserLocalService(
        await prefsFor(initial: {'favorite_user_ids': 'corrupted'}),
      );

      expect(service.readFavoriteIds(), isEmpty);
    });

    test('含非数字项：跳过坏项保留可解析项', () async {
      final service = UserLocalService(
        await prefsFor(
          initial: {
            'favorite_user_ids': <String>['1', 'x', '3'],
          },
        ),
      );

      expect(service.readFavoriteIds(), {1, 3});
    });
  });
}
