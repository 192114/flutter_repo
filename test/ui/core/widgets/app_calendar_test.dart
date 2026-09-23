import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_button.dart';
import 'package:flutter_repo/ui/core/widgets/app_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(Widget child, {Locale locale = const Locale('zh')}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(body: Center(child: child)),
    );

Widget _calendar({
  bool rangeMode = false,
  AppCalendarDisplayMode displayMode = AppCalendarDisplayMode.monthSwitch,
  DateTime? initialDate,
  AppDateRangeSelection? initialRange,
  DateTime? minDate,
  DateTime? maxDate,
  ValueChanged<DateTime>? onDateChanged,
  ValueChanged<AppDateRangeSelection>? onRangeChanged,
}) {
  var date = initialDate;
  var range = initialRange;
  return StatefulBuilder(
    builder: (context, setState) => SizedBox(
      height: 600,
      child: rangeMode
          ? AppCalendarView.range(
              value: range,
              displayMode: displayMode,
              minDate: minDate,
              maxDate: maxDate,
              onChanged: (value) {
                setState(() => range = value);
                onRangeChanged?.call(value);
              },
            )
          : AppCalendarView.single(
              value: date,
              displayMode: displayMode,
              minDate: minDate,
              maxDate: maxDate,
              onChanged: (value) {
                setState(() => date = value);
                onDateChanged?.call(value);
              },
            ),
    ),
  );
}

/// 找到某个日期数字的 Text 控件（限定在日历网格内唯一）。
Text _dayText(WidgetTester tester, String day) {
  final texts = tester.widgetList<Text>(find.text(day));
  // 月切换模式下网格内数字唯一；直接取第一个。
  return texts.first;
}

RegExp _dayLabel(WidgetTester tester, DateTime date) {
  final context = tester.element(find.byType(AppCalendarView));
  final label = MaterialLocalizations.of(context).formatFullDate(date);
  return RegExp('^${RegExp.escape(label)}');
}

void main() {
  // 在测试体前创建，避免框架在 addTearDown 之前执行语义句柄泄漏检查。
  setUp(() {
    final handle = TestWidgetsFlutterBinding.ensureInitialized()
        .ensureSemantics();
    addTearDown(handle.dispose);
  });

  group('AppCalendarView 本地化', () {
    for (final mode in AppCalendarDisplayMode.values) {
      testWidgets('英文星期和月份保留周一网格，大字无溢出 $mode', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SizedBox(
                width: 320,
                height: 580,
                child: AppCalendarView.single(
                  displayMode: mode,
                  value: DateTime(2026, 9, 15),
                  minDate: DateTime(2026, 8),
                  maxDate: DateTime(2026, 10, 31),
                  onChanged: (_) {},
                ),
              ),
            ),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('September 2026'), findsWidgets);
        final header = tester
            .widgetList<Row>(
              find.descendant(
                of: find.byType(AppCalendarView),
                matching: find.byType(Row),
              ),
            )
            .firstWhere((row) => row.children.length == 7);
        final labels = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byWidget(header),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data)
            .toList();
        expect(labels, ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
        expect(
          tester
              .getSemantics(
                find.bySemanticsLabel(_dayLabel(tester, DateTime(2026, 9, 15))),
              )
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        if (mode == AppCalendarDisplayMode.monthSwitch) {
          expect(find.byTooltip('Previous month'), findsOneWidget);
          expect(find.byTooltip('Next month'), findsOneWidget);
          await tester.tap(find.byTooltip('Next month'));
          await tester.pumpAndSettle();
          expect(find.text('October 2026'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('英文今天及范围角标和完整日期语义', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            minDate: DateTime(now.year, now.month),
            maxDate: DateTime(now.year, now.month + 1, 0),
          ),
          locale: const Locale('en'),
        ),
      );
      expect(find.text('Today'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(_dayLabel(tester, now)))
            .label,
        endsWith(', Today'),
      );
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            rangeMode: true,
            initialRange: (
              start: DateTime(2026, 9, 12),
              end: DateTime(2026, 9, 18),
            ),
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 9, 30),
          ),
          locale: const Locale('en'),
        ),
      );
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(_dayLabel(tester, DateTime(2026, 9, 12))),
            )
            .label,
        endsWith(', Start'),
      );
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(_dayLabel(tester, DateTime(2026, 9, 18))),
            )
            .label,
        endsWith(', End'),
      );
    });
  });

  group('AppCalendarView 月切换模式', () {
    testWidgets('固定 6 行网格，切换月份标题变化且高度不变', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 12, 31),
          ),
        ),
      );

      expect(find.text('2026年9月'), findsOneWidget);
      expect(find.text('一'), findsOneWidget);
      expect(find.text('日'), findsOneWidget);
      // 9 月 30 天 + 1 个前导空格 = 31 格，6 行 = 42 格，空格 11 个。
      final before = tester.getSize(find.byType(AppCalendarView));

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('2026年10月'), findsOneWidget);
      final after = tester.getSize(find.byType(AppCalendarView));
      expect(after.height, before.height);
    });

    testWidgets('到达边界月份时对应导航按钮禁用', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 10, 31),
          ),
        ),
      );

      IconButton prev() => tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_left),
      );
      IconButton next() => tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );

      expect(prev().onPressed, isNull);
      expect(next().onPressed, isNotNull);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(prev().onPressed, isNotNull);
      expect(next().onPressed, isNull);
    });

    testWidgets('范围外日期置灰且不可点击', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            minDate: DateTime(2026, 9, 10),
            maxDate: DateTime(2026, 9, 20),
            onDateChanged: (d) => picked = d,
          ),
        ),
      );

      final disabled = _dayText(tester, '5');
      expect(disabled.style?.color, AppColors.light.mutedForeground);

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(picked, isNull);

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 9, 15));
    });
  });

  group('AppCalendarView 单选', () {
    testWidgets('日期数字在列内水平居中', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(minDate: DateTime(2026, 9), maxDate: DateTime(2026, 9, 30)),
        ),
      );

      // 2026-09-15 是周二（列下标 1），测试面宽 800 → 列中心 x = 1.5 × 800/7。
      final center = tester.getCenter(find.text('15'));
      expect(center.dx, moreOrLessEquals(1.5 * 800 / 7, epsilon: 1));
    });

    testWidgets('点选日期触发回调，选中数字反白加粗', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 9, 30),
            onDateChanged: (d) => picked = d,
          ),
        ),
      );

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      expect(picked, DateTime(2026, 9, 15));
      final selected = _dayText(tester, '15');
      expect(selected.style?.color, AppColors.light.primaryForeground);
      expect(selected.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('今天显示主色数字与「今天」角标', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            minDate: DateTime(now.year, now.month),
            maxDate: DateTime(now.year, now.month + 1, 0),
          ),
        ),
      );

      expect(find.text('今'), findsOneWidget);
      final today = _dayText(tester, '${now.day}');
      expect(today.style?.color, AppColors.light.primary);
      expect(today.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('initialDate 超出范围时收敛到范围内最近日期', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            initialDate: DateTime(2026, 9, 5),
            minDate: DateTime(2026, 9, 10),
            maxDate: DateTime(2026, 9, 30),
          ),
        ),
      );

      // 早于 minDate 的初始选中收敛到 minDate 当天。
      final clamped = _dayText(tester, '10');
      expect(clamped.style?.color, AppColors.light.primaryForeground);
      expect(clamped.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('方向键移动选中日期并跨月切换', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            initialDate: DateTime(2026, 9, 15),
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 10, 31),
            onDateChanged: (d) => picked = d,
          ),
        ),
      );

      // 点选任意日期把焦点移入网格，方向键才可用。
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      picked = null;

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 9, 16));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 9, 23));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 9, 22));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 9, 15));

      // 跨月：9 月 15 日连按 30 次右移进入 10 月 15 日。
      for (var i = 0; i < 30; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      }
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 10, 15));
      expect(find.text('2026年10月'), findsOneWidget);
    });

    testWidgets('日期格语义包含完整日期与选中态', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            initialDate: DateTime(2026, 9, 15),
            minDate: DateTime(2026, 9, 10),
            maxDate: DateTime(2026, 9, 30),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(_dayLabel(tester, DateTime(2026, 9, 15))),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(_dayLabel(tester, DateTime(2026, 9, 20))),
        findsOneWidget,
      );

      final selected = tester.getSemantics(
        find.bySemanticsLabel(_dayLabel(tester, DateTime(2026, 9, 15))),
      );
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      // 范围外日期（9 月 5 日）标记为不可用。
      final disabled = tester.getSemantics(
        find.bySemanticsLabel(_dayLabel(tester, DateTime(2026, 9, 5))),
      );
      expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('minDate/maxDate 动态变化后月份缓存重建', (tester) async {
      // 固定 initialDate，避免测试依赖运行月份。
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            initialDate: DateTime(2026, 9, 15),
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 10, 31),
          ),
        ),
      );

      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            initialDate: DateTime(2026, 9, 15),
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 12, 31),
          ),
        ),
      );

      // 原范围只到 10 月；扩展后可连续切换到 11 月。
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('2026年10月'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('2026年11月'), findsOneWidget);
    });
  });

  group('AppCalendarView 范围选择', () {
    testWidgets('依次点选起止，中间日高亮且显示开始/结束角标', (tester) async {
      AppDateRangeSelection? selection;
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            rangeMode: true,
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 9, 30),
            onRangeChanged: (s) => selection = s,
          ),
        ),
      );

      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(selection?.start, DateTime(2026, 9, 12));
      expect(selection?.end, isNull);
      expect(find.text('开始'), findsOneWidget);
      expect(find.text('结束'), findsNothing);

      await tester.tap(find.text('18'));
      await tester.pumpAndSettle();
      expect(selection?.end, DateTime(2026, 9, 18));
      expect(find.text('结束'), findsOneWidget);

      // 中间日 accentForeground。
      final middle = _dayText(tester, '15');
      expect(middle.style?.color, AppColors.light.accentForeground);
      // 起止反白。
      expect(
        _dayText(tester, '12').style?.color,
        AppColors.light.primaryForeground,
      );
      expect(
        _dayText(tester, '18').style?.color,
        AppColors.light.primaryForeground,
      );
    });

    testWidgets('逆序点选自动交换起止', (tester) async {
      AppDateRangeSelection? selection;
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            rangeMode: true,
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 9, 30),
            onRangeChanged: (s) => selection = s,
          ),
        ),
      );

      await tester.tap(find.text('18'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();

      expect(selection?.start, DateTime(2026, 9, 12));
      expect(selection?.end, DateTime(2026, 9, 18));
    });

    testWidgets('完成区间后再点重新开始', (tester) async {
      AppDateRangeSelection? selection;
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            rangeMode: true,
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 9, 30),
            onRangeChanged: (s) => selection = s,
          ),
        ),
      );

      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('18'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      expect(selection?.start, DateTime(2026, 9, 20));
      expect(selection?.end, isNull);
      expect(find.text('结束'), findsNothing);
    });
  });

  group('AppCalendarView 滚动模式', () {
    testWidgets('渲染多个月份标题与周表头', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            displayMode: AppCalendarDisplayMode.scroll,
            initialDate: DateTime(2026, 9, 15),
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 12, 31),
          ),
        ),
      );

      // 月内标题 + 吸顶标题同时存在于树中（吸顶条盖在月内标题上方）。
      expect(find.text('2026年9月'), findsWidgets);
      expect(find.text('一'), findsOneWidget);
      // 600px 视口内 9 月与 10 月的 15 日均可见。
      expect(find.text('15'), findsAtLeastNWidgets(1));
      // 吸顶标题显示视口顶部月份。
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('calendar_sticky_month_title')),
          matching: find.text('2026年9月'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('仅物化视口附近的月份（默认 1900-2100 范围）', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            displayMode: AppCalendarDisplayMode.scroll,
            initialDate: DateTime(2050, 6, 15),
          ),
        ),
      );

      expect(find.text('1900年1月'), findsNothing);
      expect(find.text('2100年12月'), findsNothing);
      expect(find.text('2050年6月'), findsWidgets);
      // 视口 + 缓存区只物化少数月份（2412 个月不进入 widget 树）。
      final titles = find.textContaining(RegExp(r'^\d{4}年\d{1,2}月$'));
      expect(titles.evaluate().length, lessThan(10));
    });

    testWidgets('滚动后吸顶标题跟随顶部月份', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            displayMode: AppCalendarDisplayMode.scroll,
            initialDate: DateTime(2026, 9, 15),
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 12, 31),
          ),
        ),
      );

      // 9 月内容高 266px，上滑 300px 后顶部进入 10 月。
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('calendar_sticky_month_title')),
          matching: find.text('2026年10月'),
        ),
        findsOneWidget,
      );
    });
  });

  group('AppCalendarView 受控状态与无障碍', () {
    for (final mode in AppCalendarDisplayMode.values) {
      for (final rangeMode in [false, true]) {
        testWidgets('$mode range=$rangeMode 外部清空和跨月回填同步视图', (tester) async {
          var calls = 0;
          Widget view(DateTime? value) => _buildTestApp(
            SizedBox(
              height: 400,
              child: rangeMode
                  ? AppCalendarView.range(
                      displayMode: mode,
                      minDate: DateTime(2026),
                      maxDate: DateTime(2026, 12, 31),
                      value: value == null ? null : (start: value, end: value),
                      onChanged: (_) => calls++,
                    )
                  : AppCalendarView.single(
                      displayMode: mode,
                      minDate: DateTime(2026),
                      maxDate: DateTime(2026, 12, 31),
                      value: value,
                      onChanged: (_) => calls++,
                    ),
            ),
          );
          Finder day(int month, int day) => find.bySemanticsLabel(
            _dayLabel(tester, DateTime(2026, month, day)),
          );
          await tester.pumpWidget(view(DateTime(2026, 3, 15, 18)));
          await tester.pumpAndSettle();
          final state = tester.state(find.byType(AppCalendarView));
          expect(
            tester.getSemantics(day(3, 15)).flagsCollection.isSelected,
            Tristate.isTrue,
          );

          await tester.pumpWidget(view(null));
          await tester.pumpAndSettle();
          expect(
            tester.getSemantics(day(3, 15)).flagsCollection.isSelected,
            Tristate.isFalse,
          );
          expect(find.text('开始'), findsNothing);

          await tester.pumpWidget(view(DateTime(2026, 8, 10, 23)));
          await tester.pumpAndSettle();
          expect(tester.state(find.byType(AppCalendarView)), same(state));
          expect(
            tester.getSemantics(day(8, 10)).flagsCollection.isSelected,
            Tristate.isTrue,
          );
          if (mode == AppCalendarDisplayMode.scroll) {
            expect(
              find.descendant(
                of: find.byKey(const ValueKey('calendar_sticky_month_title')),
                matching: find.text('2026年8月'),
              ),
              findsOneWidget,
            );
          } else {
            expect(find.text('2026年8月'), findsOneWidget);
          }
          expect(calls, 0);
        });
      }
    }

    testWidgets('父级未回填时不会私自改变单选或范围值', (tester) async {
      for (final rangeMode in [false, true]) {
        var calls = 0;
        await tester.pumpWidget(
          _buildTestApp(
            rangeMode
                ? AppCalendarView.range(
                    displayMode: AppCalendarDisplayMode.monthSwitch,
                    value: (start: DateTime(2026, 9, 12), end: null),
                    minDate: DateTime(2026, 9),
                    maxDate: DateTime(2026, 9, 30),
                    onChanged: (_) => calls++,
                  )
                : AppCalendarView.single(
                    displayMode: AppCalendarDisplayMode.monthSwitch,
                    value: DateTime(2026, 9, 12),
                    minDate: DateTime(2026, 9),
                    maxDate: DateTime(2026, 9, 30),
                    onChanged: (_) => calls++,
                  ),
          ),
        );
        await tester.tap(find.text('18'));
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(
          _dayText(tester, '12').style?.color,
          AppColors.light.primaryForeground,
        );
        expect(
          _dayText(tester, '18').style?.color,
          AppColors.light.cardForeground,
        );
        expect(find.text('结束'), findsNothing);
      }
    });

    testWidgets('语义点击触发选择，空回调禁用且无点击动作', (tester) async {
      DateTime? selected;
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 9, 30),
            onDateChanged: (value) => selected = value,
          ),
        ),
      );
      final day = find.bySemanticsLabel(
        _dayLabel(tester, DateTime(2026, 9, 15)),
      );
      tester.semantics.tap(
        find.semantics.byLabel(_dayLabel(tester, DateTime(2026, 9, 15))),
      );
      await tester.pumpAndSettle();
      expect(selected, DateTime(2026, 9, 15));

      await tester.pumpWidget(
        _buildTestApp(
          AppCalendarView.single(
            displayMode: AppCalendarDisplayMode.monthSwitch,
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 9, 30),
          ),
        ),
      );
      final disabled = tester.getSemantics(day);
      expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        disabled.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      await tester.tap(find.text('15'));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(day).flagsCollection.isSelected,
        Tristate.isFalse,
      );
    });

    testWidgets('范围键盘移动焦点，空格与回车提交起止并夹紧边界', (tester) async {
      AppDateRangeSelection? selection;
      var calls = 0;
      await tester.pumpWidget(
        _buildTestApp(
          _calendar(
            rangeMode: true,
            initialRange: (start: DateTime(2026, 9, 30), end: null),
            minDate: DateTime(2026, 9, 28),
            maxDate: DateTime(2026, 10, 2),
            onRangeChanged: (value) {
              selection = value;
              calls++;
            },
          ),
        ),
      );
      final grid = find
          .descendant(
            of: find.byType(AppCalendarView),
            matching: find.byWidgetPredicate(
              (widget) => widget is Focus && widget.focusNode != null,
            ),
          )
          .first;
      tester.widget<Focus>(grid).focusNode!.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('2026年10月'), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(_dayLabel(tester, DateTime(2026, 10))),
            )
            .flagsCollection
            .isFocused,
        Tristate.isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(selection, (
        start: DateTime(2026, 9, 30),
        end: DateTime(2026, 10),
      ));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selection, (start: DateTime(2026, 10, 2), end: null));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selection, (
        start: DateTime(2026, 9, 28),
        end: DateTime(2026, 10, 2),
      ));
    });

    testWidgets('大字网格与空白行同高，滚动标题缓存同步缩放', (tester) async {
      Widget view(AppCalendarDisplayMode mode, double scale) => _buildTestApp(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: SizedBox(
            height: 560,
            child: AppCalendarView.range(
              displayMode: mode,
              value: (start: DateTime(2026, 2, 12), end: DateTime(2026, 2, 18)),
              minDate: DateTime(2026),
              maxDate: DateTime(2026, 12, 31),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpWidget(view(AppCalendarDisplayMode.monthSwitch, 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final rows = tester
          .widgetList<Row>(
            find.descendant(
              of: find.byType(AppCalendarView),
              matching: find.byType(Row),
            ),
          )
          .where((row) => row.children.length == 7)
          .toList();
      final heights = rows
          .skip(1)
          .map((row) => tester.getSize(find.byWidget(row)).height);
      expect(heights.length, 6);
      expect(heights.toSet().length, 1);
      expect(heights.first, greaterThan(46));

      await tester.pumpWidget(view(AppCalendarDisplayMode.scroll, 1));
      await tester.pumpAndSettle();
      await tester.pumpWidget(view(AppCalendarDisplayMode.scroll, 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final scroll = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      final title = find.byKey(const ValueKey('calendar_sticky_month_title'));
      expect(
        find.descendant(of: title, matching: find.text('2026年2月')),
        findsOneWidget,
      );
      final titleHeight = tester.getSize(title).height;
      final cellHeight = tester
          .getSize(
            find
                .ancestor(
                  of: find.text('15').first,
                  matching: find.byType(GestureDetector),
                )
                .first,
          )
          .height;
      final marchOffset = (titleHeight + cellHeight * 5) * 2;
      scroll.controller!.jumpTo(marchOffset);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: title, matching: find.text('2026年3月')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AppCalendarPicker', () {
    Future<void> openSheet(
      WidgetTester tester, {
      required Future<void> Function(BuildContext context) show,
      Locale locale = const Locale('zh'),
    }) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => FilledButton(
              onPressed: () => show(context),
              child: const Text('打开日历'),
            ),
          ),
          locale: locale,
        ),
      );
      await tester.tap(find.text('打开日历'));
      await tester.pumpAndSettle();
    }

    AppButton confirmButton(WidgetTester tester) =>
        tester.widget<AppButton>(find.widgetWithText(AppButton, '确定'));

    /// 缓存区会物化相邻月份，同名日期多个月都有；按树序取首月的。
    Finder dayCell(String day) => find.text(day).first;

    for (final rangeMode in [false, true]) {
      testWidgets('英文弹层默认与自定义标题，大字无溢出 range=$rangeMode', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        for (final title in <String?>[null, 'Travel dates']) {
          await openSheet(
            tester,
            locale: const Locale('en'),
            show: (context) async {
              if (rangeMode) {
                await AppCalendarPicker.showRange(
                  context,
                  title: title,
                  minDate: DateTime(2026, 9),
                  maxDate: DateTime(2026, 9, 30),
                );
              } else {
                await AppCalendarPicker.showDate(
                  context,
                  title: title,
                  minDate: DateTime(2026, 9),
                  maxDate: DateTime(2026, 9, 30),
                );
              }
            },
          );
          expect(find.text(title ?? 'Select date'), findsOneWidget);
          expect(find.text('September 2026'), findsWidgets);
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Confirm'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('单选：未选择时确定禁用，选择后返回日期', (tester) async {
      DateTime? result;
      var callbackRan = false;
      await openSheet(
        tester,
        show: (context) async {
          result = await AppCalendarPicker.showDate(
            context,
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 12, 31),
          );
          callbackRan = true;
        },
      );

      expect(find.text('选择日期'), findsOneWidget);
      expect(confirmButton(tester).onPressed, isNull);

      await tester.tap(dayCell('15'));
      await tester.pumpAndSettle();
      expect(confirmButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(callbackRan, isTrue);
      expect(result, DateTime(2026, 9, 15));
    });

    testWidgets('范围：选齐起止后确定可用，返回区间', (tester) async {
      AppDateRange? result;
      await openSheet(
        tester,
        show: (context) async {
          result = await AppCalendarPicker.showRange(
            context,
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 12, 31),
          );
        },
      );

      await tester.tap(dayCell('12'));
      await tester.pumpAndSettle();
      expect(confirmButton(tester).onPressed, isNull);

      await tester.tap(dayCell('18'));
      await tester.pumpAndSettle();
      expect(confirmButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(result?.start, DateTime(2026, 9, 12));
      expect(result?.end, DateTime(2026, 9, 18));
    });

    for (final above in [false, true]) {
      testWidgets('单选越界初值直接确认返回可见边界 above=$above', (tester) async {
        DateTime? result;
        final expected = DateTime(2026, 9, above ? 20 : 10);
        await openSheet(
          tester,
          show: (context) async {
            result = await AppCalendarPicker.showDate(
              context,
              initialDate: DateTime(2026, above ? 10 : 8, 15, 23),
              minDate: DateTime(2026, 9, 10, 18),
              maxDate: DateTime(2026, 9, 20, 6),
            );
          },
        );
        expect(
          _dayText(tester, '${expected.day}').style?.color,
          AppColors.light.primaryForeground,
        );
        await tester.tap(find.text('确定'));
        await tester.pumpAndSettle();
        expect(result, expected);
      });
    }

    testWidgets('范围初值两端裁剪并去掉时间，确认结果与视图一致', (tester) async {
      AppDateRange? result;
      await openSheet(
        tester,
        show: (context) async {
          result = await AppCalendarPicker.showRange(
            context,
            initialRange: (
              start: DateTime(2026, 8, 1, 23),
              end: DateTime(2026, 10, 1, 18),
            ),
            minDate: DateTime(2026, 9, 10, 18),
            maxDate: DateTime(2026, 9, 20, 6),
          );
        },
      );
      expect(
        _dayText(tester, '10').style?.color,
        AppColors.light.primaryForeground,
      );
      expect(
        _dayText(tester, '20').style?.color,
        AppColors.light.primaryForeground,
      );
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(result, (
        start: DateTime(2026, 9, 10),
        end: DateTime(2026, 9, 20),
      ));
    });

    testWidgets('同一天倒序时间仍视为合法日期范围', (tester) async {
      AppDateRange? result;
      await openSheet(
        tester,
        show: (context) async {
          result = await AppCalendarPicker.showRange(
            context,
            initialRange: (
              start: DateTime(2026, 9, 15, 23),
              end: DateTime(2026, 9, 15, 1),
            ),
            minDate: DateTime(2026, 9, 15, 20),
            maxDate: DateTime(2026, 9, 15, 2),
          );
        },
      );
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(result, (
        start: DateTime(2026, 9, 15),
        end: DateTime(2026, 9, 15),
      ));
    });

    testWidgets('无效范围在打开弹层前抛出错误', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(
        () => AppCalendarPicker.showDate(
          context,
          minDate: DateTime(2026, 9, 20),
          maxDate: DateTime(2026, 9, 10),
        ),
        throwsArgumentError,
      );
      expect(
        () => AppCalendarPicker.showRange(
          context,
          initialRange: (
            start: DateTime(2026, 9, 20),
            end: DateTime(2026, 9, 10),
          ),
        ),
        throwsArgumentError,
      );
      expect(find.byType(AppCalendarView), findsNothing);
    });

    testWidgets('大字弹层仍可选择并确认', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      DateTime? result;
      await openSheet(
        tester,
        show: (context) async {
          result = await AppCalendarPicker.showDate(
            context,
            initialDate: DateTime(2026, 9, 15),
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 12, 31),
          );
        },
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(result, DateTime(2026, 9, 15));
      expect(tester.takeException(), isNull);
    });

    testWidgets('取消返回 null', (tester) async {
      DateTime? result = DateTime(2000);
      await openSheet(
        tester,
        show: (context) async {
          result = await AppCalendarPicker.showDate(
            context,
            minDate: DateTime(2026, 9),
            maxDate: DateTime(2026, 12, 31),
          );
        },
      );

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });
}
