import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_selection.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(Widget child) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('单选通过父组回传 value，重复选中及禁用不触发', (tester) async {
    final values = <int?>[];
    var selected = 1;
    await tester.pumpWidget(
      _buildTestApp(
        StatefulBuilder(
          builder: (context, setState) => RadioGroup<int>(
            groupValue: selected,
            onChanged: (value) {
              values.add(value);
              setState(() => selected = value!);
            },
            child: const Column(
              children: [
                AppRadio(value: 1, label: '选项一'),
                AppRadio(value: 2, label: '选项二'),
                AppRadio(value: 3, label: '不可用', enabled: false),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('选项一'));
    expect(values, isEmpty);
    await tester.tap(find.text('选项二'));
    await tester.pumpAndSettle();
    expect(values, [2]);
    expect(selected, 2);
    await tester.tap(find.text('选项二'));
    await tester.tap(find.text('不可用'), warnIfMissed: false);
    expect(values, [2]);
  });

  testWidgets('单选 Tab/空格/方向键跨组导航，环绕且跳过禁用项', (tester) async {
    int? first;
    int? second = 4;
    final values = <int?>[];
    await tester.pumpWidget(
      _buildTestApp(
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              RadioGroup<int>(
                groupValue: first,
                onChanged: (value) {
                  values.add(value);
                  setState(() => first = value);
                },
                child: const Column(
                  children: [
                    AppRadio(value: 0, enabled: false, label: '禁用首项'),
                    AppRadio(value: 1, label: '第一组一'),
                    AppRadio(value: 2, enabled: false, label: '禁用中项'),
                    AppRadio(value: 3, label: '第一组三'),
                  ],
                ),
              ),
              RadioGroup<int>(
                groupValue: second,
                onChanged: (value) => setState(() => second = value),
                child: const Column(
                  children: [
                    AppRadio(value: 4, label: '第二组四'),
                    AppRadio(value: 5, label: '第二组五'),
                  ],
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('组后按钮')),
            ],
          ),
        ),
      ),
    );
    void expectFocused(String label) => expect(
      tester.getSemantics(find.text(label)),
      isSemantics(isFocused: true),
    );

    await _press(tester, LogicalKeyboardKey.tab);
    expectFocused('第一组一');
    expect(first, isNull);
    await _press(tester, LogicalKeyboardKey.space);
    expect(first, 1);
    await _press(tester, LogicalKeyboardKey.space);
    expect(values, [1]);
    for (final (key, expected) in [
      (LogicalKeyboardKey.arrowRight, 3),
      (LogicalKeyboardKey.arrowDown, 1),
      (LogicalKeyboardKey.arrowLeft, 3),
      (LogicalKeyboardKey.arrowUp, 1),
    ]) {
      await _press(tester, key);
      expect(first, expected);
      expectFocused(expected == 1 ? '第一组一' : '第一组三');
      expect(second, 4);
    }
    expect(values, [1, 3, 1, 3, 1]);
    await _press(tester, LogicalKeyboardKey.tab);
    expectFocused('第二组四');
    await _press(tester, LogicalKeyboardKey.arrowRight);
    expect(second, 5);
    expect(first, 1);
    await _press(tester, LogicalKeyboardKey.tab);
    expectFocused('组后按钮');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expectFocused('第二组五');
  });

  testWidgets('单选焦点环使用 ring，取消焦点后复原', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        Column(
          children: [
            RadioGroup<int>(
              groupValue: 1,
              onChanged: (_) {},
              child: const AppRadio(value: 1, label: '单选'),
            ),
            TextButton(onPressed: () {}, child: const Text('后续')),
          ],
        ),
      ),
    );
    Color focusBorder() {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AppRadio<int>),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return ((box.decoration as BoxDecoration).border! as Border).top.color;
    }

    expect(focusBorder(), Colors.transparent);
    await _press(tester, LogicalKeyboardKey.tab);
    expect(focusBorder(), AppColors.light.ring);
    await _press(tester, LogicalKeyboardKey.tab);
    expect(focusBorder(), Colors.transparent);
  });

  testWidgets('多选 value 控制勾选，点击标签回传取反后的值', (tester) async {
    var value = false;
    final values = <bool>[];
    await tester.pumpWidget(
      _buildTestApp(
        StatefulBuilder(
          builder: (context, setState) => AppCheckbox(
            value: value,
            label: '记住我',
            onChanged: (next) {
              values.add(next);
              setState(() => value = next);
            },
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsNothing);
    await tester.tap(find.text('记住我'));
    await tester.pumpAndSettle();
    expect(values, [true]);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('记住我'));
    await tester.pumpAndSettle();
    expect(values, [true, false]);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('多选与开关 Tab/空格切换且跳过禁用项', (tester) async {
    final values = <bool>[];
    await tester.pumpWidget(
      _buildTestApp(
        Column(
          children: [
            AppCheckbox(value: false, label: '多选', onChanged: values.add),
            const AppCheckbox(value: true, label: '禁用多选'),
            const AppSwitch(value: false, label: '禁用开关'),
            AppSwitch(value: true, label: '开关', onChanged: values.add),
          ],
        ),
      ),
    );
    await _press(tester, LogicalKeyboardKey.tab);
    expect(tester.getSemantics(find.text('多选')), isSemantics(isFocused: true));
    await _press(tester, LogicalKeyboardKey.space);
    expect(values, [true]);
    await _press(tester, LogicalKeyboardKey.tab);
    expect(tester.getSemantics(find.text('开关')), isSemantics(isFocused: true));
    await _press(tester, LogicalKeyboardKey.space);
    expect(values, [true, false]);
    await tester.tap(find.text('禁用多选'), warnIfMissed: false);
    await tester.tap(find.text('禁用开关'), warnIfMissed: false);
    expect(values, [true, false]);
  });

  for (final kind in _Control.values) {
    for (final enabled in [true, false]) {
      for (final selected in [true, false]) {
        testWidgets('${kind.name} enabled=$enabled value=$selected 合并标签与状态语义', (
          tester,
        ) async {
          await tester.pumpWidget(
            _buildTestApp(
              _control(kind, value: selected, enabled: enabled, label: '控制标签'),
            ),
          );
          expect(find.bySemanticsLabel('控制标签'), findsOneWidget);
          expect(
            tester.getSemantics(find.text('控制标签')),
            isSemantics(
              label: '控制标签',
              hasEnabledState: true,
              isEnabled: enabled,
              hasTapAction: enabled,
              hasCheckedState: kind != _Control.switchControl,
              isChecked: kind != _Control.switchControl && selected,
              hasToggledState: kind == _Control.switchControl,
              isToggled: kind == _Control.switchControl && selected,
              isInMutuallyExclusiveGroup: kind == _Control.radio,
            ),
          );
        });
      }
    }

    testWidgets('${kind.name} 保留设计尺寸，48px 触控区外沿可点', (tester) async {
      var taps = 0;
      final control = _control(kind, onChanged: (_) => taps++);
      await tester.pumpWidget(_buildTestApp(control));
      final bounds = tester.getRect(
        find.byType(switch (kind) {
          _Control.radio => AppRadio<int>,
          _Control.checkbox => AppCheckbox,
          _Control.switchControl => AppSwitch,
        }),
      );
      expect(bounds.width, greaterThanOrEqualTo(48));
      expect(bounds.height, 48);
      final visual = kind == _Control.switchControl
          ? find.byType(AnimatedContainer)
          : find.byWidgetPredicate(
              (widget) =>
                  widget is Container &&
                  widget.constraints?.maxWidth == 20 &&
                  widget.constraints?.maxHeight == 20,
            );
      expect(
        tester.getSize(visual),
        kind == _Control.switchControl
            ? const Size(48, 28)
            : const Size(20, 20),
      );
      for (final point in [
        Offset(bounds.center.dx, bounds.top + 1),
        Offset(bounds.center.dx, bounds.bottom - 1),
        Offset(bounds.left + 1, bounds.center.dy),
        Offset(bounds.right - 1, bounds.center.dy),
      ]) {
        await tester.tapAt(point);
      }
      expect(taps, 4);
    });

    testWidgets('${kind.name} 窄屏三倍字体完整换行且标签可点击', (tester) async {
      const label = '很长的选项说明文字需要完整显示';
      var taps = 0;
      await tester.pumpWidget(
        _buildTestApp(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(3)),
            child: SizedBox(
              width: 180,
              child: _control(kind, label: label, onChanged: (_) => taps++),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
      expect(tester.getSize(find.text(label)).height, greaterThan(48));
      await tester.tap(find.text(label));
      expect(taps, 1);
    });
  }

  for (final disableAnimations in [false, true]) {
    testWidgets('开关标签切换与减少动画 disableAnimations=$disableAnimations', (
      tester,
    ) async {
      var value = false;
      await tester.pumpWidget(
        _buildTestApp(
          MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: StatefulBuilder(
              builder: (context, setState) => AppSwitch(
                value: value,
                label: '通知',
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      );
      final duration = disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 150);
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        duration,
      );
      expect(
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).duration,
        duration,
      );
      expect(
        tester
            .widget<Align>(
              find.descendant(
                of: find.byType(AnimatedAlign),
                matching: find.byType(Align),
              ),
            )
            .alignment,
        Alignment.centerLeft,
      );
      await tester.tap(find.text('通知'));
      await tester.pump();
      if (!disableAnimations) {
        await tester.pump(const Duration(milliseconds: 75));
        final alignment =
            tester
                    .widget<Align>(
                      find.descendant(
                        of: find.byType(AnimatedAlign),
                        matching: find.byType(Align),
                      ),
                    )
                    .alignment
                as Alignment;
        expect(alignment.x, allOf(greaterThan(-1), lessThan(1)));
        await tester.pumpAndSettle();
      }
      expect(value, isTrue);
      expect(
        tester
            .widget<Align>(
              find.descendant(
                of: find.byType(AnimatedAlign),
                matching: find.byType(Align),
              ),
            )
            .alignment,
        Alignment.centerRight,
      );
    });
  }
}

enum _Control { radio, checkbox, switchControl }

Widget _control(
  _Control kind, {
  bool value = false,
  bool enabled = true,
  String? label,
  ValueChanged<bool>? onChanged,
}) {
  final callback = enabled ? (onChanged ?? (_) {}) : null;
  return switch (kind) {
    _Control.radio => RadioGroup<int>(
      groupValue: value ? 1 : null,
      onChanged: (_) => callback?.call(true),
      child: AppRadio(value: 1, enabled: enabled, label: label),
    ),
    _Control.checkbox => AppCheckbox(
      value: value,
      onChanged: callback,
      label: label,
    ),
    _Control.switchControl => AppSwitch(
      value: value,
      onChanged: callback,
      label: label,
    ),
  };
}
