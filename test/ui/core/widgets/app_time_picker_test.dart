import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_picker.dart';
import 'package:flutter_repo/ui/core/widgets/app_time_picker.dart';
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
  required ValueChanged<TimeOfDay?> onResult,
  TimeOfDay? initialTime,
  TimeOfDay? minTime,
  TimeOfDay? maxTime,
  int minuteInterval = 1,
  String? title,
  Locale locale = const Locale('zh'),
}) async {
  await tester.pumpWidget(
    _buildTestApp(
      Builder(
        builder: (context) => FilledButton(
          onPressed: () async => onResult(
            await AppTimePicker.show(
              context,
              initialTime: initialTime,
              minTime: minTime,
              maxTime: maxTime,
              minuteInterval: minuteInterval,
              title: title,
            ),
          ),
          child: const Text('打开'),
        ),
      ),
      locale: locale,
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

AppPickerWheel _wheelAt(WidgetTester tester, int index) =>
    tester.widget<AppPickerWheel>(find.byType(AppPickerWheel).at(index));

void main() {
  for (final title in <String?>[null, 'Alarm']) {
    testWidgets('英文时间标题及自定义覆盖保持24小时两列，大字无溢出 title=$title', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      TimeOfDay? result;
      await _openPicker(
        tester,
        initialTime: const TimeOfDay(hour: 23, minute: 45),
        title: title,
        locale: const Locale('en'),
        onResult: (value) => result = value,
      );
      expect(find.text(title ?? 'Select time'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(AppPickerWheel), findsNWidgets(2));
      expect(
        _wheelAt(tester, 0).items,
        List.generate(24, (i) => '$i'.padLeft(2, '0')),
      );
      expect(_wheelAt(tester, 0).selectedIndex, 23);
      expect(_wheelAt(tester, 1).selectedIndex, 45);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(result, const TimeOfDay(hour: 23, minute: 45));
      expect(tester.takeException(), isNull);
    });
  }

  for (final sample in [
    (
      initial: const TimeOfDay(hour: 8, minute: 0),
      expected: const TimeOfDay(hour: 9, minute: 15),
    ),
    (
      initial: const TimeOfDay(hour: 12, minute: 0),
      expected: const TimeOfDay(hour: 10, minute: 45),
    ),
    (
      initial: const TimeOfDay(hour: 9, minute: 53),
      expected: const TimeOfDay(hour: 10, minute: 0),
    ),
  ]) {
    testWidgets('步长15与非整点边界对齐 ${sample.initial}', (tester) async {
      TimeOfDay? result;
      await _openPicker(
        tester,
        initialTime: sample.initial,
        minTime: const TimeOfDay(hour: 9, minute: 7),
        maxTime: const TimeOfDay(hour: 10, minute: 52),
        minuteInterval: 15,
        onResult: (value) => result = value,
      );
      final hour = _wheelAt(tester, 0);
      final minute = _wheelAt(tester, 1);
      expect(int.parse(hour.items[hour.selectedIndex]), sample.expected.hour);
      expect(
        int.parse(minute.items[minute.selectedIndex]),
        sample.expected.minute,
      );
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(result, sample.expected);
    });
  }

  testWidgets('等距取较早候选，步长60支持当天首尾小时', (tester) async {
    for (final sample in [
      (
        initial: const TimeOfDay(hour: 9, minute: 30),
        expected: const TimeOfDay(hour: 9, minute: 0),
      ),
      (
        initial: const TimeOfDay(hour: 23, minute: 59),
        expected: const TimeOfDay(hour: 23, minute: 0),
      ),
      (
        initial: const TimeOfDay(hour: 0, minute: 0),
        expected: const TimeOfDay(hour: 0, minute: 0),
      ),
    ]) {
      TimeOfDay? result;
      await _openPicker(
        tester,
        initialTime: sample.initial,
        minuteInterval: 60,
        onResult: (value) => result = value,
      );
      expect(_wheelAt(tester, 1).items, ['00']);
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(result, sample.expected);
    }
  });

  testWidgets('切换边界小时联动分钟列表并对齐滚轮位置', (tester) async {
    TimeOfDay? result;
    await _openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 9, minute: 45),
      minTime: const TimeOfDay(hour: 9, minute: 37),
      maxTime: const TimeOfDay(hour: 11, minute: 7),
      minuteInterval: 15,
      onResult: (value) => result = value,
    );
    expect(_wheelAt(tester, 1).items, ['45']);
    _wheelAt(tester, 0).onSelected(1);
    await tester.pumpAndSettle();
    expect(_wheelAt(tester, 1).items, ['00', '15', '30', '45']);
    expect(_wheelAt(tester, 1).selectedIndex, 3);
    _wheelAt(tester, 0).onSelected(2);
    await tester.pumpAndSettle();
    expect(_wheelAt(tester, 1).items, ['00']);
    expect(_wheelAt(tester, 1).selectedIndex, 0);
    final wheel = tester.widget<ListWheelScrollView>(
      find.byType(ListWheelScrollView).at(1),
    );
    expect((wheel.controller! as FixedExtentScrollController).selectedItem, 0);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, const TimeOfDay(hour: 11, minute: 0));
  });

  testWidgets('步长无效、跨午夜及无候选区间在打开前报错', (tester) async {
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
    for (final interval in [0, -1, 7, 120]) {
      expect(
        () => AppTimePicker.show(context, minuteInterval: interval),
        throwsArgumentError,
      );
    }
    expect(
      () => AppTimePicker.show(
        context,
        minTime: const TimeOfDay(hour: 23, minute: 0),
        maxTime: const TimeOfDay(hour: 1, minute: 0),
      ),
      throwsArgumentError,
    );
    expect(
      () => AppTimePicker.show(
        context,
        minTime: const TimeOfDay(hour: 9, minute: 1),
        maxTime: const TimeOfDay(hour: 9, minute: 14),
        minuteInterval: 15,
      ),
      throwsArgumentError,
    );
    expect(find.byType(AppPickerSheet), findsNothing);
  });

  testWidgets('同一合法时刻的闭区间可确认，大字布局无溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    TimeOfDay? result;
    await _openPicker(
      tester,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
      minTime: const TimeOfDay(hour: 9, minute: 15),
      maxTime: const TimeOfDay(hour: 9, minute: 15),
      minuteInterval: 15,
      onResult: (value) => result = value,
    );
    expect(tester.takeException(), isNull);
    expect(_wheelAt(tester, 0).items, ['09']);
    expect(_wheelAt(tester, 1).items, ['15']);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(result, const TimeOfDay(hour: 9, minute: 15));
    expect(tester.takeException(), isNull);
  });

  testWidgets('时间选择：初始时间确认后返回', (tester) async {
    TimeOfDay? result;

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await AppTimePicker.show(
                context,
                initialTime: const TimeOfDay(hour: 14, minute: 30),
              );
            },
            child: const Text('打开时间'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开时间'));
    await tester.pumpAndSettle();

    expect(find.text('选择时间'), findsOneWidget);
    // 初始滚轮停在中行：14 与 30 以主色加粗展示。
    expect(find.text('14'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(result, const TimeOfDay(hour: 14, minute: 30));
  });

  testWidgets('时间选择：取消返回 null', (tester) async {
    var callbackRan = false;
    TimeOfDay? result;

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await AppTimePicker.show(
                context,
                initialTime: const TimeOfDay(hour: 9, minute: 0),
              );
              callbackRan = true;
            },
            child: const Text('打开时间'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开时间'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(callbackRan, isTrue);
    expect(result, isNull);
  });
}
