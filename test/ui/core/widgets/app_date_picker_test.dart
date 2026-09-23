import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_date_picker.dart';
import 'package:flutter_repo/ui/core/widgets/app_picker.dart';
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

Future<void> _openPicker(
  WidgetTester tester, {
  required void Function(DateTime?) onResult,
  DateTime? initialDate,
  DateTime? minDate,
  DateTime? maxDate,
  String? title,
  Locale locale = const Locale('zh'),
}) async {
  await tester.pumpWidget(
    _buildTestApp(
      Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            final date = await AppDatePicker.show(
              context,
              initialDate: initialDate,
              minDate: minDate,
              maxDate: maxDate,
              title: title,
            );
            onResult(date);
          },
          child: const Text('打开日期'),
        ),
      ),
      locale: locale,
    ),
  );

  await tester.tap(find.text('打开日期'));
  await tester.pumpAndSettle();
}

AppPickerWheel _wheelAt(WidgetTester tester, int index) =>
    tester.widget<AppPickerWheel>(find.byType(AppPickerWheel).at(index));

void main() {
  for (final title in <String?>[null, 'Birthday']) {
    testWidgets('英文日期标题及滚轮格式，自定义覆盖且大字无溢出 title=$title', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      DateTime? result;
      await _openPicker(
        tester,
        initialDate: DateTime(2026, 9, 20),
        locale: const Locale('en'),
        title: title,
        onResult: (value) => result = value,
      );
      expect(find.text(title ?? 'Select date'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(
        _wheelAt(tester, 0).items[_wheelAt(tester, 0).selectedIndex],
        '2026',
      );
      expect(_wheelAt(tester, 1).items, List.generate(12, (i) => '${i + 1}'));
      expect(
        _wheelAt(tester, 2).items[_wheelAt(tester, 2).selectedIndex],
        '20',
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, DateTime(2026, 9, 20));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('初值和同日边界忽略时间，直接确认返回午夜', (tester) async {
    DateTime? result;
    await _openPicker(
      tester,
      initialDate: DateTime(2026, 9, 15, 23, 59),
      minDate: DateTime(2026, 9, 15, 20),
      maxDate: DateTime(2026, 9, 15, 1),
      onResult: (value) => result = value,
    );
    expect(_wheelAt(tester, 2).items, ['15日']);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 9, 15));
  });

  testWidgets('超过上界的带时间初值收敛到上界日期', (tester) async {
    DateTime? result;
    await _openPicker(
      tester,
      initialDate: DateTime(2027, 1, 1, 23),
      minDate: DateTime(2026, 9, 10, 18),
      maxDate: DateTime(2026, 9, 20, 6),
      onResult: (value) => result = value,
    );
    expect(_wheelAt(tester, 2).items[_wheelAt(tester, 2).selectedIndex], '20日');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 9, 20));
  });

  testWidgets('闰日切换平年夹紧，滚轮位置与返回日期一致', (tester) async {
    DateTime? result;
    await _openPicker(
      tester,
      initialDate: DateTime(2024, 2, 29),
      minDate: DateTime(2024),
      maxDate: DateTime(2025, 12, 31),
      onResult: (value) => result = value,
    );
    _wheelAt(tester, 0).onSelected(1);
    await tester.pumpAndSettle();
    expect(_wheelAt(tester, 2).selectedIndex, 27);
    final wheel = tester.widget<ListWheelScrollView>(
      find.byType(ListWheelScrollView).at(2),
    );
    expect((wheel.controller! as FixedExtentScrollController).selectedItem, 27);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2025, 2, 28));
  });

  testWidgets('无效日期范围在打开前报错', (tester) async {
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
      () => AppDatePicker.show(
        context,
        minDate: DateTime(2026, 9, 20),
        maxDate: DateTime(2026, 9, 10),
      ),
      throwsArgumentError,
    );
    expect(find.byType(AppPickerSheet), findsNothing);
  });

  testWidgets('大字日期滚轮无溢出且直接确认不改变日期', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    DateTime? result;
    await _openPicker(
      tester,
      initialDate: DateTime(2026, 9, 20),
      onResult: (value) => result = value,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 9, 20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('日期选择：三列滚轮展示年月日，确认返回初始日期', (tester) async {
    DateTime? result;
    var callbackRan = false;

    await _openPicker(
      tester,
      initialDate: DateTime(2026, 9, 20),
      onResult: (date) {
        result = date;
        callbackRan = true;
      },
    );

    expect(find.text('选择日期'), findsOneWidget);
    expect(find.byType(AppPickerWheel), findsNWidgets(3));
    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('9月'), findsOneWidget);
    expect(find.text('20日'), findsOneWidget);
    // 默认范围 1900-01-01 ~ 2100-12-31。
    expect(_wheelAt(tester, 0).items.first, '1900年');
    expect(_wheelAt(tester, 0).items.last, '2100年');
    expect(_wheelAt(tester, 0).items.length, 201);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(callbackRan, isTrue);
    expect(result, DateTime(2026, 9, 20));
  });

  testWidgets('日期选择：滚动选择月与日，确认返回新日期', (tester) async {
    DateTime? result;

    await _openPicker(
      tester,
      initialDate: DateTime(2026, 9, 20),
      onResult: (date) => result = date,
    );

    _wheelAt(tester, 1).onSelected(9); // 10月
    await tester.pumpAndSettle();
    _wheelAt(tester, 2).onSelected(24); // 25日
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(result, DateTime(2026, 10, 25));
  });

  testWidgets('日期选择：取消返回 null', (tester) async {
    var callbackRan = false;
    DateTime? result;

    await _openPicker(
      tester,
      onResult: (date) {
        result = date;
        callbackRan = true;
      },
    );

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(callbackRan, isTrue);
    expect(result, isNull);
  });

  testWidgets('日期选择：切换到闰年二月时日数联动并夹紧', (tester) async {
    DateTime? result;

    await _openPicker(
      tester,
      initialDate: DateTime(2024, 1, 31),
      onResult: (date) => result = date,
    );

    expect(_wheelAt(tester, 2).items.length, 31);

    _wheelAt(tester, 1).onSelected(1); // 2月
    await tester.pumpAndSettle();

    // 2024 为闰年：2 月 29 天，31 日被夹紧到 29 日。
    expect(_wheelAt(tester, 2).items.length, 29);
    expect(_wheelAt(tester, 2).selectedIndex, 28);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(result, DateTime(2024, 2, 29));
  });

  testWidgets('日期选择：min/max 裁剪年月日滚轮列表', (tester) async {
    DateTime? result;

    await _openPicker(
      tester,
      initialDate: DateTime(2021, 6, 10),
      minDate: DateTime(2020, 6, 15),
      maxDate: DateTime(2023, 3, 10),
      onResult: (date) => result = date,
    );

    expect(_wheelAt(tester, 0).items, ['2020年', '2021年', '2022年', '2023年']);

    // 切到下界年：月从 6 月起，起点月的日从 15 日起。
    _wheelAt(tester, 0).onSelected(0);
    await tester.pumpAndSettle();
    expect(_wheelAt(tester, 1).items.first, '6月');
    expect(_wheelAt(tester, 1).items.length, 7);
    expect(_wheelAt(tester, 2).items.first, '15日');

    // 切到上界年：月止于 3 月，终点月的日止于 10 日。
    _wheelAt(tester, 0).onSelected(3);
    await tester.pumpAndSettle();
    expect(_wheelAt(tester, 1).items, ['1月', '2月', '3月']);
    expect(_wheelAt(tester, 2).items.last, '10日');

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(result, DateTime(2023, 3, 10));
  });

  testWidgets('日期选择：初始日期超出范围被夹紧到边界', (tester) async {
    DateTime? result;

    await _openPicker(
      tester,
      initialDate: DateTime(2019),
      minDate: DateTime(2020, 6, 15),
      maxDate: DateTime(2023, 3, 10),
      onResult: (date) => result = date,
    );

    expect(_wheelAt(tester, 0).selectedIndex, 0);
    expect(_wheelAt(tester, 1).items.first, '6月');
    expect(_wheelAt(tester, 2).items.first, '15日');

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(result, DateTime(2020, 6, 15));
  });
}
