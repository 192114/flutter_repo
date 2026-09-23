import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_dropdown_menu.dart';
import 'package:flutter_test/flutter_test.dart';

const _titleKey0 = Key('app_dropdown_menu_title_0');
const _titleKey1 = Key('app_dropdown_menu_title_1');
const _maskKey = Key('app_dropdown_menu_mask');

Widget _buildTestApp(
  Widget child, {
  ThemeData? theme,
  Locale locale = const Locale('zh'),
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  theme: theme ?? AppTheme.light,
  home: Scaffold(body: child),
);

void _ignoreChange(String value) {}

Widget _buildMenu({
  String? selectedValue,
  ValueChanged<String>? onChanged = _ignoreChange,
}) => AppDropdownMenu(
  items: [
    AppDropdownMenuItem<String>(
      title: '综合排序',
      value: selectedValue,
      onChanged: onChanged,
      options: const [
        AppDropdownMenuOption(label: '综合排序', value: '综合排序'),
        AppDropdownMenuOption(label: '最新优先', value: '最新优先'),
        AppDropdownMenuOption(label: '价格从低到高', value: '价格从低到高'),
        AppDropdownMenuOption(label: '价格从高到低', value: '价格从高到低', enabled: false),
      ],
    ),
    AppDropdownMenuItem<String>(
      title: '筛选',
      onChanged: _ignoreChange,
      options: const [
        AppDropdownMenuOption(label: '全部', value: '全部'),
        AppDropdownMenuOption(label: '只看有货', value: '只看有货'),
      ],
    ),
  ],
  child: const Text('页面内容'),
);

void main() {
  for (final preview in [dropdownMenuLightPreview, dropdownMenuDarkPreview]) {
    testWidgets('下拉菜单预览可展开并同步选中标题', (tester) async {
      await tester.pumpWidget(preview());
      await tester.pumpAndSettle();
      await tester.tap(find.text('综合排序'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('最新优先'));
      await tester.pumpAndSettle();
      expect(find.text('最新优先'), findsOneWidget);
      expect(find.text('综合排序'), findsNothing);
    });
  }

  testWidgets('英文菜单收起语义本地化而自定义选项保持原样', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _buildTestApp(_buildMenu(), locale: const Locale('en')),
    );
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Collapse menu'), findsOneWidget);
    expect(find.text('最新优先'), findsOneWidget);
    await tester.tap(find.byKey(_maskKey));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Collapse menu'), findsNothing);
    semantics.dispose();
  });

  testWidgets('菜单栏渲染标题与内容，初始不展开面板', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildMenu()));

    expect(find.text('综合排序'), findsOneWidget);
    expect(find.text('筛选'), findsOneWidget);
    expect(find.text('页面内容'), findsOneWidget);
    expect(find.text('最新优先'), findsNothing);
    expect(find.byKey(_maskKey), findsNothing);

    final title = tester.widget<Text>(find.text('综合排序'));
    expect(title.style?.fontSize, 15);
    expect(title.style?.color, AppColors.light.foreground);
  });

  // 回归：BoxShadow 默认 BlurStyle.normal 会把内阴影画进栏内，
  // 装饰必须显式填充背景色将其覆盖，否则菜单栏整体被洗灰。
  testWidgets('菜单栏装饰显式填充背景色（白色），不被阴影内晕染灰', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildMenu()));

    final barBox = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byKey(_titleKey0),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = barBox.decoration as BoxDecoration;
    expect(decoration.color, AppColors.light.card);
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('点击标题展开面板：标题变主色、箭头翻转、遮罩出现', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildMenu(selectedValue: '综合排序')));
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();

    // 标题与面板选中项各出现一次。
    expect(find.text('综合排序'), findsNWidgets(2));
    expect(find.text('最新优先'), findsOneWidget);
    expect(find.text('价格从低到高'), findsOneWidget);
    expect(find.text('价格从高到低'), findsOneWidget);

    final titleColor = tester
        .widgetList<Text>(find.text('综合排序'))
        .map((t) => t.style?.color);
    expect(titleColor.every((c) => c == AppColors.light.primary), isTrue);

    final rotation = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation).first,
    );
    expect(rotation.turns, 0.5);

    final mask = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(_maskKey),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(mask.color, Colors.black.withValues(alpha: 0.6));
  });

  testWidgets('选中项行尾展示主色对勾，非选中项无对勾', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildMenu(selectedValue: '综合排序')));
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();

    final check = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(check.color, AppColors.light.primary);
    expect(find.byIcon(Icons.check), findsOneWidget);

    final normalOption = tester.widget<Text>(find.text('最新优先'));
    expect(normalOption.style?.color, AppColors.light.cardForeground);

    final disabledOption = tester.widget<Text>(find.text('价格从高到低'));
    expect(disabledOption.style?.color, AppColors.light.mutedForeground);
  });

  testWidgets('点击选项触发回调并收起面板', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _buildTestApp(_buildMenu(onChanged: (v) => selected = v)),
    );
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('最新优先'));
    await tester.pumpAndSettle();

    expect(selected, '最新优先');
    expect(find.text('最新优先'), findsNothing);
    expect(find.byKey(_maskKey), findsNothing);
  });

  testWidgets('点击遮罩收起面板', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildMenu()));
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();
    expect(find.text('最新优先'), findsOneWidget);

    await tester.tap(find.byKey(_maskKey));
    await tester.pumpAndSettle();

    expect(find.text('最新优先'), findsNothing);
    expect(find.byKey(_maskKey), findsNothing);
  });

  testWidgets('再次点击激活标题收起面板', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildMenu()));
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();

    expect(find.text('最新优先'), findsNothing);
    expect(find.byKey(_maskKey), findsNothing);
  });

  testWidgets('禁用选项不触发回调且面板保持展开', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _buildTestApp(_buildMenu(onChanged: (_) => called = true)),
    );
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('价格从高到低'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.text('最新优先'), findsOneWidget);
  });

  testWidgets('展开时点击其他标题直接切换面板内容', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildMenu()));
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_titleKey1));
    await tester.pumpAndSettle();

    expect(find.text('最新优先'), findsNothing);
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('只看有货'), findsOneWidget);

    final firstRotation = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation).first,
    );
    expect(firstRotation.turns, 0);
  });

  testWidgets('暗色主题使用暗色 token：主色对勾与 70% 遮罩', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(_buildMenu(selectedValue: '综合排序'), theme: AppTheme.dark),
    );
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();

    final check = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(check.color, AppColors.dark.primary);

    final titleColor = tester
        .widgetList<Text>(find.text('综合排序'))
        .map((t) => t.style?.color);
    expect(titleColor.every((c) => c == AppColors.dark.primary), isTrue);

    final mask = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(_maskKey),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(mask.color, Colors.black.withValues(alpha: 0.7));
  });

  testWidgets('Esc 收起面板并把焦点归还给展开过的标题', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildMenu()));
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();
    expect(find.text('最新优先'), findsOneWidget);

    // 键盘流：聚焦标题后按 Esc。
    final title = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(_titleKey0),
        matching: find.byType(InkWell),
      ),
    );
    title.focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('最新优先'), findsNothing);
    expect(find.byKey(_maskKey), findsNothing);
    expect(title.focusNode!.hasFocus, isTrue);
  });

  testWidgets('展开期间选项列表变化时面板就地更新且不崩溃', (tester) async {
    String? selected;
    Widget menu(int optionCount) => AppDropdownMenu(
      items: [
        AppDropdownMenuItem<String>(
          title: '综合排序',
          value: selected,
          onChanged: (v) => selected = v,
          options: [
            for (var i = 0; i < optionCount; i++)
              AppDropdownMenuOption(label: '选项$i', value: '选项$i'),
          ],
        ),
      ],
      child: const Text('页面内容'),
    );

    await tester.pumpWidget(_buildTestApp(menu(4)));
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();
    expect(find.text('选项3'), findsOneWidget);

    // 展开状态下外部把选项换成两项：面板就地更新，不越界崩溃。
    await tester.pumpWidget(_buildTestApp(menu(2)));
    await tester.pumpAndSettle();

    expect(find.text('选项3'), findsNothing);
    expect(find.text('选项0'), findsOneWidget);
    expect(find.text('选项1'), findsOneWidget);

    // 选择仍正常：触发回调并收起。
    await tester.tap(find.text('选项1'));
    await tester.pumpAndSettle();
    expect(selected, '选项1');
    expect(find.text('选项1'), findsNothing);
  });

  testWidgets('null 回调的标题禁用且不展开', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildMenu(onChanged: null)));
    final title = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(_titleKey0),
        matching: find.byType(InkWell),
      ),
    );
    expect(title.onTap, isNull);
    expect(
      tester.widget<Text>(find.text('综合排序')).style?.color,
      AppColors.light.mutedForeground,
    );
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();
    expect(find.byKey(_maskKey), findsNothing);
  });

  testWidgets('同帧双点及退出动画期间旧回调只分发一次', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _buildTestApp(_buildMenu(onChanged: (_) => calls++)),
    );
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();
    final staleTap = tester
        .widget<InkWell>(
          find
              .ancestor(of: find.text('最新优先'), matching: find.byType(InkWell))
              .first,
        )
        .onTap!;

    await tester.tap(find.text('最新优先'));
    await tester.tap(find.text('最新优先'));
    expect(calls, 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    staleTap();
    expect(calls, 1);
    expect(
      tester
          .widget<InkWell>(
            find
                .ancestor(of: find.text('最新优先'), matching: find.byType(InkWell))
                .first,
          )
          .onTap,
      isNull,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_maskKey), findsNothing);
  });

  testWidgets('点击遮罩开始关闭后旧选项不能触发选择', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _buildTestApp(_buildMenu(onChanged: (_) => calls++)),
    );
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();
    final staleTap = tester
        .widget<InkWell>(
          find
              .ancestor(of: find.text('最新优先'), matching: find.byType(InkWell))
              .first,
        )
        .onTap!;
    await tester.tap(find.byKey(_maskKey));
    staleTap();
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.byKey(_maskKey), findsNothing);
  });

  for (final change in ['disabled', 'callback', 'options']) {
    testWidgets('展开期间 $change 失效自动收起且旧回调不可用', (tester) async {
      var calls = 0;
      Widget menu(bool changed) => AppDropdownMenu(
        items: [
          AppDropdownMenuItem<int>(
            title: '动态菜单',
            enabled: !(changed && change == 'disabled'),
            onChanged: changed && change == 'callback' ? null : (_) => calls++,
            options: changed && change == 'options'
                ? const []
                : const [AppDropdownMenuOption(label: '选项', value: 1)],
          ),
        ],
        child: const Text('内容'),
      );
      await tester.pumpWidget(_buildTestApp(menu(false)));
      await tester.tap(find.byKey(_titleKey0));
      await tester.pumpAndSettle();
      final staleTap = tester
          .widget<InkWell>(
            find
                .ancestor(of: find.text('选项'), matching: find.byType(InkWell))
                .first,
          )
          .onTap!;
      await tester.pumpWidget(_buildTestApp(menu(true)));
      staleTap();
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.byKey(_maskKey), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('展开菜单被移除后清理面板与焦点节点', (tester) async {
    var calls = 0;
    final first = AppDropdownMenuItem<String>(
      title: '首项',
      onChanged: (_) => calls++,
      options: const [AppDropdownMenuOption(label: '文字', value: 'text')],
    );
    final second = AppDropdownMenuItem<int>(
      title: '次项',
      onChanged: (_) => calls++,
      options: const [AppDropdownMenuOption(label: '数字', value: 42)],
    );
    Widget menu(bool removed) => AppDropdownMenu(
      items: [first, if (!removed) second],
      child: const Text('内容'),
    );
    await tester.pumpWidget(_buildTestApp(menu(false)));
    await tester.tap(find.byKey(_titleKey1));
    await tester.pumpAndSettle();
    final staleTap = tester
        .widget<InkWell>(
          find
              .ancestor(of: find.text('数字'), matching: find.byType(InkWell))
              .first,
        )
        .onTap!;
    await tester.pumpWidget(_buildTestApp(menu(true)));
    staleTap();
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.byKey(_maskKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('异构非空泛型菜单正确分发 String 和 int', (tester) async {
    String? stringValue;
    int? intValue;
    await tester.pumpWidget(
      _buildTestApp(
        AppDropdownMenu(
          items: [
            AppDropdownMenuItem<String>(
              title: '文字菜单',
              onChanged: (value) => stringValue = value,
              options: const [
                AppDropdownMenuOption(label: '文字', value: 'value'),
              ],
            ),
            AppDropdownMenuItem<int>(
              title: '数字菜单',
              onChanged: (value) => intValue = value,
              options: const [AppDropdownMenuOption(label: '数字', value: 42)],
            ),
          ],
          child: const Text('内容'),
        ),
      ),
    );
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('文字'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_titleKey1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('数字'));
    await tester.pumpAndSettle();
    expect(stringValue, 'value');
    expect(intValue, 42);
    expect(tester.takeException(), isNull);
  });

  testWidgets('退出动画中重新展开不被旧动画结束回调移除', (tester) async {
    await tester.pumpWidget(_buildTestApp(_buildMenu()));
    await tester.tap(find.byKey(_titleKey0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_titleKey0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(_titleKey1));
    await tester.pumpAndSettle();
    expect(find.text('全部'), findsOneWidget);
    expect(find.byKey(_maskKey), findsOneWidget);
  });
}
