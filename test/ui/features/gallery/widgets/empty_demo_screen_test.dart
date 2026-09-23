import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_empty.dart';
import 'package:flutter_repo/ui/features/gallery/widgets/empty_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDemo(WidgetTester tester, {bool dark = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: const EmptyDemoScreen(),
      ),
    );
  }

  for (final dark in [false, true]) {
    testWidgets('${dark ? '深' : '浅'}色演示页展示设计稿场景且操作可点击', (tester) async {
      await pumpDemo(tester, dark: dark);
      expect(find.text('空状态组件演示'), findsOneWidget);
      expect(find.text('这里还没有内容'), findsOneWidget);
      await tester.tap(find.text('创建内容'));
      await tester.pump();
      expect(find.text('创建内容回调已触发'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      for (final (title, action, feedback) in [
        ('没有找到相关结果', '清除筛选', '清除筛选回调已触发'),
        ('还没有收藏', '去发现', '去发现回调已触发'),
      ]) {
        await tester.scrollUntilVisible(find.text(action), 250);
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        await tester.tap(find.text(action));
        await tester.pump();
        expect(find.text(feedback), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
      }

      await tester.scrollUntilVisible(find.text('暂无记录'), 250);
      expect(find.text('暂无数据'), findsOneWidget);
      expect(find.text('暂无记录'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (name, preview) in [
    ('浅色', emptyLightPreview),
    ('深色', emptyDarkPreview),
  ]) {
    testWidgets('$name 预览反馈不越过主题和 Overlay 边界', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 390, height: 500, child: preview()),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('创建内容'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('创建内容'));
      await tester.pump();
      expect(find.text('创建内容回调已触发'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
    });
  }

  testWidgets('自定义示例可独立开关描述和操作且保留图标标题', (tester) async {
    await pumpDemo(tester);
    final descriptionToggle = find.byKey(const Key('empty-toggle-description'));
    final actionToggle = find.byKey(const Key('empty-toggle-action'));
    final custom = find.byKey(const Key('empty-custom'));
    await tester.scrollUntilVisible(descriptionToggle, 300);
    await tester.ensureVisible(descriptionToggle);
    await tester.pumpAndSettle();
    await tester.tap(descriptionToggle);
    await tester.pumpAndSettle();
    expect(tester.widget<AppEmpty>(custom).description, isNull);
    expect(tester.widget<AppEmpty>(custom).action, isNotNull);

    await tester.ensureVisible(actionToggle);
    await tester.pumpAndSettle();
    await tester.tap(actionToggle);
    await tester.pumpAndSettle();
    expect(tester.widget<AppEmpty>(custom).action, isNull);
    expect(find.text('你的自定义标题'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);

    await tester.ensureVisible(descriptionToggle);
    await tester.pumpAndSettle();
    await tester.tap(descriptionToggle);
    await tester.pumpAndSettle();
    expect(tester.widget<AppEmpty>(custom).description, isNotNull);
    expect(tester.widget<AppEmpty>(custom).action, isNull);

    await tester.ensureVisible(actionToggle);
    await tester.pumpAndSettle();
    await tester.tap(actionToggle);
    await tester.pumpAndSettle();
    for (final label in ['主要操作', '次要操作']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pump();
      expect(find.text('$label回调已触发'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    }
    expect(tester.takeException(), isNull);
  });
}
