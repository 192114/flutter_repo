// Widget 测试：通过 ProviderScope 注入 FakeUserRepository，
// 整棵 Widget 树在无网络、无本地存储的环境下即可完整运行。

import 'package:flutter/material.dart';
import 'package:flutter_repo/app.dart';
import 'package:flutter_repo/data/repositories/user_repository.dart';
import 'package:flutter_repo/data/services/user_local_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_user_repository.dart';

Widget _buildApp(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      // App 启动链依赖 sharedPreferencesProvider（主题偏好恢复），
      // 测试环境必须用 mock 实例注入，否则会抛 UnimplementedError。
      sharedPreferencesProvider.overrideWithValue(prefs),
      // 依赖注入的威力：一行代码把真实 Repository 换成 Fake。
      userRepositoryProvider.overrideWithValue(FakeUserRepository()),
    ],
    child: const App(),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('用户列表渲染（注入 Fake Repository，无网络依赖）',
      (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();

    expect(find.text('用户列表'), findsOneWidget);
    expect(find.text('Leanne Graham'), findsOneWidget);
    expect(find.text('Ervin Howell'), findsOneWidget);
    expect(find.text('Clementine Bauch'), findsOneWidget);
  });

  testWidgets('搜索交互：输入后仅显示匹配项（单向数据流）', (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();

    // 模拟用户输入 → onChanged → ViewModel.onQueryChanged → 新状态 → 重建。
    await tester.enterText(find.byType(TextField), 'ervin');
    await tester.pump();

    expect(find.text('Leanne Graham'), findsNothing);
    expect(find.text('Ervin Howell'), findsOneWidget);
  });

  testWidgets('点击用户卡片通过 go_router 跳转详情页', (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leanne Graham'));
    await tester.pumpAndSettle();

    expect(find.text('用户详情'), findsOneWidget);
    expect(find.text('Romaguera-Crona'), findsWidgets);
  });

  testWidgets('主题切换：默认跟随系统，选择深色后 themeMode 变为 dark',
      (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();

    MaterialApp materialApp() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp));

    // 未做选择时跟随系统。
    expect(materialApp().themeMode, ThemeMode.system);

    await tester.tap(find.byTooltip('主题模式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    expect(materialApp().themeMode, ThemeMode.dark);
    // 选择已持久化（下次启动恢复）。
    expect(prefs.getString('app_theme_mode'), 'dark');
  });
}
