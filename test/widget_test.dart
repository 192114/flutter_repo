// Widget 测试：通过 ProviderScope 注入 FakeUserRepository，
// 整棵 Widget 树在无网络、无本地存储的环境下即可完整运行。

import 'package:flutter/material.dart';
import 'package:flutter_repo/app.dart';
import 'package:flutter_repo/data/repositories/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_user_repository.dart';

Widget _buildApp() {
  return ProviderScope(
    overrides: [
      // 依赖注入的威力：一行代码把真实 Repository 换成 Fake。
      userRepositoryProvider.overrideWithValue(FakeUserRepository()),
    ],
    child: const App(),
  );
}

void main() {
  testWidgets('用户列表渲染（注入 Fake Repository，无网络依赖）',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('用户列表'), findsOneWidget);
    expect(find.text('Leanne Graham'), findsOneWidget);
    expect(find.text('Ervin Howell'), findsOneWidget);
    expect(find.text('Clementine Bauch'), findsOneWidget);
  });

  testWidgets('搜索交互：输入后仅显示匹配项（单向数据流）', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // 模拟用户输入 → onChanged → ViewModel.onQueryChanged → 新状态 → 重建。
    await tester.enterText(find.byType(TextField), 'ervin');
    await tester.pump();

    expect(find.text('Leanne Graham'), findsNothing);
    expect(find.text('Ervin Howell'), findsOneWidget);
  });

  testWidgets('点击用户卡片通过 go_router 跳转详情页', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leanne Graham'));
    await tester.pumpAndSettle();

    expect(find.text('用户详情'), findsOneWidget);
    expect(find.text('Romaguera-Crona'), findsWidgets);
  });
}
