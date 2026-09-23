import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/features/gallery/widgets/tag_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: const TagDemoScreen(),
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('演示页展示全部标签分区', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    expect(find.text('标签组件演示'), findsOneWidget);
    expect(find.text('实心'), findsOneWidget);
    expect(find.text('空心'), findsOneWidget);

    await _scrollTo(tester, find.text('可删除'));
    expect(find.text('可删除'), findsOneWidget);

    await _scrollTo(tester, find.text('尺寸'));
    expect(find.text('尺寸'), findsOneWidget);
    expect(find.text('大号'), findsOneWidget);
  });

  testWidgets('可删除标签点击关闭后从列表移除', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _scrollTo(tester, find.byKey(const Key('closable-tag-园林')));
    expect(find.text('园林'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('closable-tag-园林')),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('园林'), findsNothing);
    expect(find.text('苏州'), findsOneWidget);
  });
}
