import 'package:flutter/material.dart';
import 'package:flutter_repo/app.dart';
import 'package:flutter_repo/data/models/user.dart';
import 'package:flutter_repo/data/repositories/user_repository.dart';
import 'package:flutter_repo/data/services/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../fakes/controllable_user_repository.dart';
import '../../../../fakes/fake_user_repository.dart';

Widget _buildApp(SharedPreferences prefs, UserRepository repository) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      userRepositoryProvider.overrideWithValue(repository),
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

  testWidgets('暂无用户时可下拉刷新并显示新数据', (tester) async {
    final repository = ControllableUserRepository();
    await tester.pumpWidget(_buildApp(prefs, repository));
    repository.listRequests.single.complete([]);
    await tester.pumpAndSettle();

    expect(find.text('暂无用户'), findsOneWidget);
    expect(find.text('下拉刷新试试'), findsOneWidget);
    expect(find.textContaining('没有匹配'), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(repository.listRequests, hasLength(2));

    repository.listRequests.last.complete(const [User(id: 1, name: 'Alice')]);
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('暂无用户'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索无结果时仍可刷新且保留搜索词', (tester) async {
    final repository = ControllableUserRepository();
    await tester.pumpWidget(_buildApp(prefs, repository));
    repository.listRequests.single.complete(const [User(id: 1, name: 'Alice')]);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bob');
    await tester.pump();
    expect(find.text('没有匹配「Bob」的用户'), findsOneWidget);
    expect(find.text('暂无用户'), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(repository.listRequests, hasLength(2));

    repository.listRequests.last.complete(const [
      User(id: 1, name: 'Alice'),
      User(id: 2, name: 'Bob'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('没有匹配「Bob」的用户'), findsNothing);
    expect(find.text('Alice'), findsNothing);
    expect(find.widgetWithText(Card, 'Bob'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Bob',
    );
  });

  testWidgets('清空无结果搜索后恢复原列表', (tester) async {
    await tester.pumpWidget(_buildApp(prefs, FakeUserRepository()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'no-such-user');
    await tester.pump();
    expect(find.text('没有匹配「no-such-user」的用户'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Leanne Graham'), findsOneWidget);
    expect(find.text('Ervin Howell'), findsOneWidget);
    expect(find.byType(CustomScrollView), findsNothing);
  });

  testWidgets('数据源为空时空白搜索词仍显示暂无用户', (tester) async {
    await tester.pumpWidget(_buildApp(prefs, FakeUserRepository(users: [])));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(find.text('暂无用户'), findsOneWidget);
    expect(find.textContaining('没有匹配'), findsNothing);
  });

  testWidgets('窄屏大字体下长搜索词空态可滚动且无溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_buildApp(prefs, FakeUserRepository()));
    await tester.pumpAndSettle();
    final query = List.filled(20, '不存在的用户').join();
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();

    expect(find.text('没有匹配「$query」的用户'), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
