import 'package:flutter/material.dart';
import 'package:flutter_repo/app.dart';
import 'package:flutter_repo/data/repositories/user_repository.dart';
import 'package:flutter_repo/data/services/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../fakes/fake_user_repository.dart';

Widget _buildApp(SharedPreferences prefs) => ProviderScope(
  overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    userRepositoryProvider.overrideWithValue(FakeUserRepository()),
  ],
  child: const App(),
);

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> openGallery(WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('组件库'));
    await tester.pumpAndSettle();
  }

  testWidgets('索引页渲染全部组件入口', (tester) async {
    await openGallery(tester);

    expect(find.text('组件库'), findsOneWidget);
    expect(find.byKey(const Key('gallery-entry-feedback')), findsOneWidget);
    expect(find.byKey(const Key('gallery-entry-dropdown')), findsOneWidget);
    expect(find.byKey(const Key('gallery-entry-async')), findsOneWidget);
    expect(find.byKey(const Key('gallery-entry-tokens')), findsOneWidget);
  });

  testWidgets('索引页各入口可跳转到对应演示页并返回', (tester) async {
    await openGallery(tester);

    await tester.tap(find.byKey(const Key('gallery-entry-feedback')));
    await tester.pumpAndSettle();
    expect(find.text('反馈组件演示'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gallery-entry-dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('机械键盘'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gallery-entry-async')));
    await tester.pumpAndSettle();
    expect(find.text('三态切换'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gallery-entry-tokens')));
    await tester.pumpAndSettle();
    // primary 与 ring 同值，允许多个匹配。
    expect(find.text('#465BF0'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('组件库'), findsOneWidget);
  });

  testWidgets('空状态入口可打开演示页并返回索引', (tester) async {
    await openGallery(tester);
    final entry = find.byKey(const Key('gallery-entry-empty'));
    await tester.scrollUntilVisible(entry, 300);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text('空状态组件演示'), findsOneWidget);
    expect(find.text('这里还没有内容'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('组件库'), findsOneWidget);
    expect(entry, findsOneWidget);
  });
}
