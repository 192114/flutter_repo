// ThemeModeNotifier 单元测试：初始恢复、落盘优先、非法值回落、落盘失败。

import 'package:flutter/material.dart';
import 'package:flutter_repo/data/exceptions/app_exception.dart';
import 'package:flutter_repo/data/services/shared_preferences_provider.dart';
import 'package:flutter_repo/ui/core/theme/app_theme_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../fakes/failing_shared_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  });

  tearDown(() => container.dispose());

  test('默认跟随系统（无持久化记录）', () {
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('setMode 更新状态并完成落盘', () async {
    await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString('app_theme_mode'), 'dark');
  });

  test('重启后从本地存储恢复用户选择', () async {
    await container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

    // 模拟重启：同一 prefs，全新容器。
    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);

    expect(restarted.read(themeModeProvider), ThemeMode.light);
  });

  test('存储值非法时安全回落 system', () async {
    await prefs.setString('app_theme_mode', 'rainbow');

    final fresh = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(fresh.dispose);

    expect(fresh.read(themeModeProvider), ThemeMode.system);
  });

  test('落盘失败：上抛 CacheException 且保持当前模式', () async {
    // 换用写入永远失败的 store，模拟磁盘写入失败。
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = FailingWriteStore();
    final failingPrefs = await SharedPreferences.getInstance();
    final failing = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(failingPrefs)],
    );
    addTearDown(failing.dispose);

    expect(failing.read(themeModeProvider), ThemeMode.system);
    await expectLater(
      failing.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
      throwsA(isA<CacheException>()),
    );
    // 落盘失败未更新状态。
    expect(failing.read(themeModeProvider), ThemeMode.system);
    // 未持久化（reload 后缓存与磁盘一致）。
    expect(failingPrefs.getString('app_theme_mode'), isNull);
  });
}
