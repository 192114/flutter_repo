// Widget 测试：通过 ProviderScope 注入 FakeUserRepository，
// 整棵 Widget 树在无网络、无本地存储的环境下即可完整运行。

import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_repo/app.dart';
import 'package:flutter_repo/data/repositories/user_repository.dart';
import 'package:flutter_repo/data/services/shared_preferences_provider.dart';
import 'package:flutter_repo/ui/core/router/app_router.dart';
import 'package:flutter_repo/ui/features/gallery/widgets/feedback_demo_screen.dart';
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

  testWidgets('用户列表渲染（注入 Fake Repository，无网络依赖）', (tester) async {
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

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets(
      '搜索框：${kind.name} 点击空白失焦并收起键盘，保留搜索内容',
      (tester) async {
        await tester.pumpWidget(_buildApp(prefs));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'ervin');
        await tester.pumpAndSettle();
        final editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.focusNode.hasFocus, isTrue);
        expect(tester.testTextInput.isVisible, isTrue);

        final blank =
            tester.getBottomRight(find.byType(Scaffold)) - const Offset(24, 24);
        await tester.tapAt(blank, kind: kind);
        await tester.pumpAndSettle();

        expect(editable.focusNode.hasFocus, isFalse);
        expect(tester.testTextInput.isVisible, isFalse);
        expect(editable.controller.text, 'ervin');
        expect(find.text('Ervin Howell'), findsOneWidget);

        await tester.tap(find.byType(TextField), kind: kind);
        await tester.pumpAndSettle();
        expect(editable.focusNode.hasFocus, isTrue);
        expect(tester.testTextInput.isVisible, isTrue);
      },
      variant: TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
  }

  testWidgets(
    '表单输入框：框内点击和密码显隐保持焦点，可切换输入框并点击空白失焦',
    (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(App)),
      );
      container.read(goRouterProvider).goNamed(AppRoute.galleryForm.name);
      await tester.pumpAndSettle();

      final username = find.widgetWithText(TextField, '请输入用户名');
      await tester.scrollUntilVisible(
        username,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final password = find.descendant(
        of: find.byKey(const Key('input-password')),
        matching: find.byType(TextField),
      );
      await tester.enterText(password, 'secret');
      await tester.pumpAndSettle();
      final passwordEditable = tester.widget<EditableText>(
        find.descendant(of: password, matching: find.byType(EditableText)),
      );
      expect(passwordEditable.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(password);
      await tester.pumpAndSettle();
      expect(passwordEditable.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(password).obscureText, isFalse);
      expect(passwordEditable.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(passwordEditable.controller.text, 'secret');

      await tester.tap(username);
      await tester.pumpAndSettle();
      final usernameEditable = tester.widget<EditableText>(
        find.descendant(of: username, matching: find.byType(EditableText)),
      );
      expect(passwordEditable.focusNode.hasFocus, isFalse);
      expect(usernameEditable.focusNode.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tapAt(Offset(8, tester.getCenter(username).dy));
      await tester.pumpAndSettle();
      expect(usernameEditable.focusNode.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('点击组件库入口打开组件库索引页', (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('组件库'));
    await tester.pumpAndSettle();

    expect(find.text('组件库'), findsOneWidget);
    expect(find.text('反馈组件'), findsOneWidget);
    expect(find.text('下拉菜单'), findsOneWidget);
    expect(find.text('异步状态'), findsOneWidget);
    expect(find.text('Design Token'), findsOneWidget);
  });

  testWidgets(
    '点击用户卡片进入详情与返回均有中间动画帧',
    (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leanne Graham'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final route = ModalRoute.of(tester.element(find.text('用户详情')))!;
      expect(route.settings, isA<MaterialPage<void>>());
      expect(route.animation!.status, AnimationStatus.forward);
      expect(route.animation!.value, allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(find.text('Romaguera-Crona'), findsWidgets);

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(route.animation!.status, AnimationStatus.reverse);
      expect(route.animation!.value, allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(find.text('用户详情'), findsNothing);
      expect(find.text('用户列表'), findsOneWidget);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    '组件库嵌套页面进入与返回均有中间动画帧',
    (tester) async {
      await tester.pumpWidget(_buildApp(prefs));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('组件库'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('反馈组件'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final route = ModalRoute.of(
        tester.element(find.byType(FeedbackDemoScreen)),
      )!;
      expect(route.animation!.status, AnimationStatus.forward);
      expect(route.animation!.value, allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(route.animation!.status, AnimationStatus.reverse);
      expect(route.animation!.value, allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(find.text('组件库'), findsOneWidget);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('iOS 边缘返回手势可以取消或完成', (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leanne Graham'));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.text('用户详情')))!;
    final width = tester.getSize(find.byType(Scaffold)).width;

    final cancelGesture = await tester.startGesture(const Offset(1, 300));
    await cancelGesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await cancelGesture.moveBy(Offset(width * 0.2, 0));
    await tester.pump();
    expect(route.navigator!.userGestureInProgress, isTrue);
    expect(route.animation!.value, allOf(greaterThan(0), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 500));
    await cancelGesture.up();
    await tester.pumpAndSettle();
    expect(find.text('用户详情'), findsOneWidget);
    expect(route.animation!.value, 1);

    final popGesture = await tester.startGesture(const Offset(1, 300));
    await popGesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await popGesture.moveBy(Offset(width * 0.75, 0));
    await tester.pump();
    expect(route.navigator!.userGestureInProgress, isTrue);
    expect(route.animation!.value, allOf(greaterThan(0), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 500));
    await popGesture.up();
    await tester.pumpAndSettle();
    expect(find.text('用户详情'), findsNothing);
    expect(find.text('用户列表'), findsOneWidget);
  }, variant: TargetPlatformVariant({TargetPlatform.iOS}));

  testWidgets('所有路由显式使用 SDK MaterialPage 并保留页面元数据', (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();
    final router = tester.container().read(goRouterProvider);
    final locations = {
      '/users': AppRoute.userList,
      '/users/1': AppRoute.userDetail,
      '/users/abc': AppRoute.userDetail,
      '/gallery': AppRoute.gallery,
      '/gallery/feedback': AppRoute.galleryFeedback,
      '/gallery/dropdown': AppRoute.galleryDropdown,
      '/gallery/async-value': AppRoute.galleryAsync,
      '/gallery/tokens': AppRoute.galleryTokens,
      '/gallery/form': AppRoute.galleryForm,
      '/gallery/tag': AppRoute.galleryTag,
      '/gallery/upload': AppRoute.galleryUpload,
      '/gallery/empty': AppRoute.galleryEmpty,
      '/image-crop/expired': AppRoute.imageCrop,
    };

    for (final entry in locations.entries) {
      router.go('${entry.key}?source=test');
      await tester.pumpAndSettle();
      final pages = tester.widget<Navigator>(find.byType(Navigator)).pages;
      expect(pages, everyElement(isA<MaterialPage<Object?>>()));
      final page = pages.last;
      expect(page.name, entry.value.name);
      expect(page.key, isA<ValueKey<String>>());
      expect(page.restorationId, (page.key! as ValueKey<String>).value);
      expect(page.arguments, containsPair('source', 'test'));
      if (entry.value == AppRoute.userDetail ||
          entry.value == AppRoute.imageCrop) {
        expect(page.arguments, containsPair('id', entry.key.split('/').last));
      }
    }
  });

  testWidgets('裁剪路由保留 Uint8List 返回类型', (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();
    final router = tester.container().read(goRouterProvider);
    final result = router.push<Uint8List>('/image-crop/expired');
    await tester.pumpAndSettle();
    final page = tester.widget<Navigator>(find.byType(Navigator)).pages.last;
    expect(page, isA<MaterialPage<Uint8List>>());

    final bytes = Uint8List.fromList([1, 2, 3]);
    router.pop(bytes);
    expect(await result, same(bytes));
    await tester.pumpAndSettle();
    expect(find.text('用户列表'), findsOneWidget);
  });

  testWidgets('无效用户 ID 深链进入兜底页而非构建崩溃', (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(App)),
    );
    container.read(goRouterProvider).go('/users/abc');
    await tester.pumpAndSettle();

    expect(find.text('无效的用户 ID'), findsOneWidget);
  });

  testWidgets('主题切换：默认跟随系统，选择深色后 themeMode 变为 dark', (tester) async {
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
