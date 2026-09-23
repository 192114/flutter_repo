import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/features/gallery/widgets/dropdown_menu_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';

const _sortTitleKey = Key('app_dropdown_menu_title_0');
const _filterTitleKey = Key('app_dropdown_menu_title_1');

Widget _buildTestApp() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  theme: AppTheme.light,
  home: const DropdownMenuDemoScreen(),
);

void main() {
  testWidgets('初始渲染菜单与全部商品', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    expect(find.text('综合排序'), findsOneWidget);
    expect(find.text('筛选'), findsOneWidget);
    expect(find.text('机械键盘'), findsOneWidget);
    expect(find.text('降噪耳机'), findsOneWidget);
    expect(find.text('缺货'), findsOneWidget);
    expect(find.text('¥1299'), findsOneWidget);
  });

  testWidgets('选择价格排序后菜单标题与商品顺序实时更新', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.tap(find.byKey(_sortTitleKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('价格从低到高'));
    await tester.pumpAndSettle();

    // 菜单标题跟随选中值。
    expect(find.text('价格从低到高'), findsOneWidget);
    expect(find.text('综合排序'), findsNothing);

    // 价格升序：无线鼠标(99) 在 机械键盘(329) 之前。
    double dyOf(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(dyOf('无线鼠标'), lessThan(dyOf('机械键盘')));
    expect(dyOf('机械键盘'), lessThan(dyOf('人体工学椅')));
  });

  testWidgets('筛选只看有货后缺货商品被移除', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.tap(find.byKey(_filterTitleKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text('只看有货'));
    await tester.pumpAndSettle();

    expect(find.text('只看有货'), findsOneWidget);
    expect(find.text('降噪耳机'), findsNothing);
    expect(find.text('机械键盘'), findsOneWidget);
  });
}
