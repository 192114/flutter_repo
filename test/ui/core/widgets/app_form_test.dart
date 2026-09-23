import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/theme/app_tokens.dart';
import 'package:flutter_repo/ui/core/widgets/app_calendar.dart';
import 'package:flutter_repo/ui/core/widgets/app_form.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(
  Widget child, {
  ThemeData? theme,
  Locale locale = const Locale('zh'),
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  theme: theme ?? AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

MaterialLocalizations _materialL10n(WidgetTester tester) =>
    MaterialLocalizations.of(tester.element(find.byType(Scaffold)));

Material _materialOf(WidgetTester tester, Finder scope) =>
    tester.widget<Material>(
      find.descendant(of: scope, matching: find.byType(Material)).first,
    );

void _noop() {}
String _display(String value) => value;

void main() {
  for (final formField in [false, true]) {
    final kind = formField ? 'FormField' : '字段';
    testWidgets('英文 $kind 默认占位和日期标签本地化', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Column(
            children: [
              if (formField) ...[
                AppPickerFormField<String>(displayStringForOption: _display),
                AppDateRangeFormField(),
              ] else ...[
                const AppPickerField(),
                const AppFormDateRangeField(),
              ],
            ],
          ),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('Please select'), findsOneWidget);
      expect(find.text('Select date'), findsNWidgets(2));
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('End date'), findsOneWidget);
      expect(find.text('请选择'), findsNothing);
      expect(find.text('选择日期'), findsNothing);
      expect(
        tester.widget<AppPickerField>(find.byType(AppPickerField)).placeholder,
        isNull,
      );
      final range = tester.widget<AppFormDateRangeField>(
        find.byType(AppFormDateRangeField),
      );
      expect(range.startLabel, isNull);
      expect(range.endLabel, isNull);
    });

    testWidgets('英文 $kind 保留自定义占位、标签和语义', (tester) async {
      final semantics = tester.ensureSemantics();
      final selected = (
        start: DateTime(2026, 9, 22),
        end: DateTime(2026, 9, 25),
      );
      await tester.pumpWidget(
        _buildTestApp(
          Column(
            children: [
              if (formField) ...[
                AppPickerFormField<String>(
                  displayStringForOption: _display,
                  placeholder: 'Choose a city',
                  semanticLabel: 'Destination',
                  onPick: (_) async => null,
                ),
                AppDateRangeFormField(
                  initialValue: selected,
                  startLabel: 'Check-in',
                  endLabel: 'Check-out',
                  semanticLabel: 'Stay dates',
                  onPick: (_) async => null,
                ),
              ] else ...[
                const AppPickerField(
                  placeholder: 'Choose a city',
                  semanticLabel: 'Destination',
                  onTap: _noop,
                ),
                AppFormDateRangeField(
                  range: selected,
                  startLabel: 'Check-in',
                  endLabel: 'Check-out',
                  semanticLabel: 'Stay dates',
                  onTap: _noop,
                ),
              ],
            ],
          ),
          locale: const Locale('en'),
        ),
      );

      expect(find.text('Choose a city'), findsOneWidget);
      expect(find.text('Check-in'), findsOneWidget);
      expect(find.text('Check-out'), findsOneWidget);
      expect(find.text('Please select'), findsNothing);
      expect(find.text('Start date'), findsNothing);
      expect(find.text('End date'), findsNothing);
      expect(find.bySemanticsLabel('Destination'), findsOneWidget);
      final materialL10n = _materialL10n(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Stay dates')).value,
        'Check-in: ${materialL10n.formatCompactDate(selected.start)}, '
        'Check-out: ${materialL10n.formatCompactDate(selected.end)}',
      );
      semantics.dispose();
    });
  }

  for (final locale in [const Locale('zh'), const Locale('en')]) {
    testWidgets('$locale 日期显示和区间语义使用本地化起止日期', (tester) async {
      final semantics = tester.ensureSemantics();
      final selected = (
        start: DateTime(2026, 1, 2),
        end: DateTime(2026, 12, 25),
      );
      await tester.pumpWidget(
        _buildTestApp(
          AppDateRangeFormField(
            initialValue: selected,
            onPick: (_) async => null,
          ),
          locale: locale,
        ),
      );

      final context = tester.element(find.byType(AppFormDateRangeField));
      final l10n = AppLocalizations.of(context)!;
      final materialL10n = MaterialLocalizations.of(context);
      final start = materialL10n.formatCompactDate(selected.start);
      final end = materialL10n.formatCompactDate(selected.end);
      expect(find.text(start), findsOneWidget);
      expect(find.text(end), findsOneWidget);
      expect(find.text('2026-01-02'), findsNothing);
      final node = tester.getSemantics(
        find.bySemanticsLabel(materialL10n.dateRangePickerHelpText),
      );
      expect(node.value, '${l10n.startDate}: $start, ${l10n.endDate}: $end');
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });
  }

  testWidgets('切换 locale 重新解析默认文案和日期且保留 FormField 状态', (tester) async {
    final fieldKey = GlobalKey<FormFieldState<AppDateRange>>();
    final selected = (start: DateTime(2026, 9, 22), end: DateTime(2026, 9, 25));
    Widget build(Locale locale) => _buildTestApp(
      Column(
        children: [
          const AppPickerField(),
          AppDateRangeFormField(key: fieldKey, initialValue: selected),
          const AppFormDateRangeField(),
        ],
      ),
      locale: locale,
    );
    await tester.pumpWidget(build(const Locale('zh')));
    expect(find.text('请选择'), findsOneWidget);
    expect(find.text('选择日期'), findsNWidgets(2));
    expect(find.text('开始日期'), findsNWidgets(2));
    final fieldState = fieldKey.currentState!;
    final chineseDate = _materialL10n(tester).formatCompactDate(selected.start);
    expect(find.text(chineseDate), findsOneWidget);

    await tester.pumpWidget(build(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Please select'), findsOneWidget);
    expect(find.text('Select date'), findsNWidgets(2));
    expect(find.text('Start date'), findsNWidgets(2));
    expect(find.text(chineseDate), findsNothing);
    expect(
      find.text(_materialL10n(tester).formatCompactDate(selected.start)),
      findsOneWidget,
    );
    expect(fieldKey.currentState, same(fieldState));
    expect(fieldKey.currentState!.value, selected);
  });

  testWidgets('picker 接入 Form 校验、保存、重置并只渲染一次错误', (tester) async {
    final form = GlobalKey<FormState>();
    String? saved;
    final changed = <String?>[];
    await tester.pumpWidget(
      _buildTestApp(
        Form(
          key: form,
          child: AppFormItem(
            label: '地区',
            child: AppPickerFormField<String>(
              displayStringForOption: _display,
              onPick: (_) async => '杭州',
              onChanged: changed.add,
              validator: (value) => value == null ? '请选择地区' : null,
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      ),
    );

    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('请选择地区'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    await tester.tap(find.text('请选择'));
    await tester.pump();
    expect(form.currentState!.validate(), isTrue);
    await tester.pump();
    expect(find.text('请选择地区'), findsNothing);
    expect(find.text('杭州'), findsOneWidget);
    form.currentState!.save();
    expect(saved, '杭州');
    expect(changed, ['杭州']);
    form.currentState!.reset();
    await tester.pump();
    expect(find.text('请选择'), findsOneWidget);
    form.currentState!.save();
    expect(saved, isNull);
  });

  testWidgets('picker 外部错误覆盖 validator 并可清除', (tester) async {
    final form = GlobalKey<FormState>();
    var validations = 0;
    Widget build(String? error) => _buildTestApp(
      Form(
        key: form,
        child: AppPickerFormField<String>(
          initialValue: '杭州',
          displayStringForOption: _display,
          errorText: error,
          validator: (_) {
            validations++;
            return '本地错误';
          },
        ),
      ),
    );
    await tester.pumpWidget(build('服务端错误'));
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(validations, 0);
    expect(find.text('服务端错误'), findsOneWidget);
    expect(find.text('本地错误'), findsNothing);
    await tester.pumpWidget(build(null));
    expect(find.text('服务端错误'), findsNothing);
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(validations, 1);
    expect(find.text('本地错误'), findsOneWidget);
  });

  testWidgets('picker 交互后自动校验，取消不改值或触发 onChanged', (tester) async {
    final field = GlobalKey<FormFieldState<String>>();
    final changed = <String?>[];
    final inputs = <String?>[];
    String? next;
    await tester.pumpWidget(
      _buildTestApp(
        AppPickerFormField<String>(
          key: field,
          initialValue: '杭州',
          displayStringForOption: _display,
          onPick: (value) async {
            inputs.add(value);
            return next;
          },
          onChanged: changed.add,
          validator: (value) => value == '无效' ? '重新选择' : null,
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ),
    );
    await tester.tap(find.text('杭州'));
    await tester.pump();
    expect(field.currentState!.value, '杭州');
    expect(field.currentState!.hasInteractedByUser, isFalse);
    expect(changed, isEmpty);
    next = '无效';
    await tester.tap(find.text('杭州'));
    await tester.pump();
    expect(inputs, ['杭州', '杭州']);
    expect(changed, ['无效']);
    expect(find.text('重新选择'), findsOneWidget);
  });

  testWidgets('picker 等待时禁用，reset 废弃返回值但保持弹层互斥', (tester) async {
    final form = GlobalKey<FormState>();
    final result = Completer<String?>();
    var opened = 0;
    final changed = <String?>[];
    await tester.pumpWidget(
      _buildTestApp(
        Form(
          key: form,
          child: AppPickerFormField<String>(
            initialValue: '原值',
            displayStringForOption: _display,
            onPick: (_) {
              opened++;
              return result.future;
            },
            onChanged: changed.add,
          ),
        ),
      ),
    );
    final onTap = tester
        .widget<AppPickerField>(find.byType(AppPickerField))
        .onTap!;
    onTap();
    onTap();
    await tester.pump();
    expect(opened, 1);
    expect(
      tester.widget<AppPickerField>(find.byType(AppPickerField)).enabled,
      isFalse,
    );
    form.currentState!.reset();
    await tester.pump();
    onTap();
    expect(opened, 1);
    result.complete('过期值');
    await tester.pumpAndSettle();
    expect(find.text('原值'), findsOneWidget);
    expect(changed, isEmpty);
    expect(
      tester.widget<AppPickerField>(find.byType(AppPickerField)).enabled,
      isTrue,
    );
    await tester.tap(find.text('原值'));
    await tester.pump();
    expect(opened, 2);
    expect(changed, ['过期值']);
  });

  for (final change in ['disabled', 'initialValue']) {
    testWidgets('picker $change 变化废弃过期结果且保留互斥', (tester) async {
      final result = Completer<String?>();
      final changed = <String?>[];
      var opened = 0;
      Widget build({bool enabled = true, String value = '原值'}) => _buildTestApp(
        AppPickerFormField<String>(
          initialValue: value,
          displayStringForOption: _display,
          enabled: enabled,
          onPick: (_) {
            opened++;
            return result.future;
          },
          onChanged: changed.add,
        ),
      );
      await tester.pumpWidget(build());
      await tester.tap(find.text('原值'));
      await tester.pump();
      if (change == 'disabled') {
        await tester.pumpWidget(build(enabled: false));
        await tester.pumpWidget(build());
      } else {
        await tester.pumpWidget(build(value: '新初值'));
      }
      final picker = tester.widget<AppPickerField>(find.byType(AppPickerField));
      expect(picker.enabled, isFalse);
      picker.onTap!();
      expect(opened, 1);
      result.complete('过期值');
      await tester.pump();
      expect(changed, isEmpty);
      expect(find.text(change == 'disabled' ? '原值' : '新初值'), findsOneWidget);
      expect(
        tester.widget<AppPickerField>(find.byType(AppPickerField)).enabled,
        isTrue,
      );
    });
  }

  testWidgets('picker 初始禁用不打开且 dispose 后不提交或 setState', (tester) async {
    final result = Completer<String?>();
    var opened = 0;
    final changed = <String?>[];
    Widget build(bool enabled) => _buildTestApp(
      AppPickerFormField<String>(
        displayStringForOption: _display,
        enabled: enabled,
        onPick: (_) {
          opened++;
          return result.future;
        },
        onChanged: changed.add,
      ),
    );
    await tester.pumpWidget(build(false));
    await tester.tap(find.text('请选择'));
    expect(opened, 0);
    await tester.pumpWidget(build(true));
    await tester.tap(find.text('请选择'));
    expect(opened, 1);
    await tester.pumpWidget(_buildTestApp(const SizedBox()));
    result.complete('已选择');
    await tester.pump();
    expect(changed, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final synchronous in [true, false]) {
    testWidgets(
      'custom picker ${synchronous ? '同步' : '异步'}异常向外传播且 finally 解锁',
      (tester) async {
        late Future<void> Function() pick;
        var enabled = true;
        var fail = true;
        final failure = StateError('选择失败');
        await tester.pumpWidget(
          _buildTestApp(
            AppPickerFormField<String>.custom(
              onPick: (_) {
                if (fail) {
                  if (synchronous) throw failure;
                  return Future<String?>.error(failure);
                }
                return Future.value('重试成功');
              },
              fieldBuilder: (context, value, onTap, active, errorText) {
                pick = onTap!;
                enabled = active;
                return Text(value ?? '请选择');
              },
            ),
          ),
        );
        await expectLater(pick(), throwsA(same(failure)));
        await tester.pump();
        expect(enabled, isTrue);
        fail = false;
        await pick();
        await tester.pump();
        expect(find.text('重试成功'), findsOneWidget);
      },
    );
  }

  testWidgets('日期 FormField 共用校验、异步确认、保存与重置', (tester) async {
    final form = GlobalKey<FormState>();
    final selected = (start: DateTime(2026, 9, 22), end: DateTime(2026, 9, 25));
    AppDateRange? saved;
    final changed = <AppDateRange?>[];
    await tester.pumpWidget(
      _buildTestApp(
        Form(
          key: form,
          child: AppDateRangeFormField(
            onPick: (value) async {
              expect(value, isNull);
              return selected;
            },
            validator: (value) => value == null ? '请选择区间' : null,
            onSaved: (value) => saved = value,
            onChanged: changed.add,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('请选择区间'), findsOneWidget);
    await tester.tap(find.text('开始日期'));
    await tester.pump();
    expect(find.text('请选择区间'), findsNothing);
    expect(
      find.text(_materialL10n(tester).formatCompactDate(selected.start)),
      findsOneWidget,
    );
    expect(changed, [selected]);
    form.currentState!.save();
    expect(saved, selected);
    form.currentState!.reset();
    await tester.pump();
    expect(find.text('选择日期'), findsNWidgets(2));
    expect(find.text('请选择区间'), findsNothing);
    form.currentState!.save();
    expect(saved, isNull);
  });

  testWidgets('日期 FormField 外部错误显示一次且 reset 废弃异步返回', (tester) async {
    final field = GlobalKey<FormFieldState<AppDateRange>>();
    final result = Completer<AppDateRange?>();
    final changed = <AppDateRange?>[];
    await tester.pumpWidget(
      _buildTestApp(
        AppDateRangeFormField(
          key: field,
          errorText: '服务端日期错误',
          onPick: (_) => result.future,
          onChanged: changed.add,
        ),
      ),
    );
    expect(field.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('服务端日期错误'), findsOneWidget);
    await tester.tap(find.text('开始日期'));
    await tester.pump();
    expect(
      tester
          .widget<AppFormDateRangeField>(find.byType(AppFormDateRangeField))
          .enabled,
      isFalse,
    );
    field.currentState!.reset();
    result.complete((start: DateTime(2026, 9, 22), end: DateTime(2026, 9, 25)));
    await tester.pump();
    expect(field.currentState!.value, isNull);
    expect(changed, isEmpty);
  });

  testWidgets('上方标签渲染标签、必填星号与占位文案', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppFormItem(
          label: '所在地区',
          required: true,
          child: AppPickerField(),
        ),
      ),
    );

    expect(find.text('所在地区'), findsOneWidget);
    final star = tester.widget<Text>(find.text('*'));
    expect(star.style?.color, AppColors.light.destructive);

    final placeholder = tester.widget<Text>(find.text('请选择'));
    expect(placeholder.style?.color, AppColors.light.mutedForeground);
  });

  testWidgets('错误文案优先于辅助文案且使用危险色', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppFormItem(
          label: '手机号',
          required: true,
          helper: '用于登录',
          errorText: '请输入11位手机号',
          child: Text('138'),
        ),
      ),
    );

    expect(find.text('请输入11位手机号'), findsOneWidget);
    expect(find.text('用于登录'), findsNothing);
    final errorText = tester.widget<Text>(find.text('请输入11位手机号'));
    expect(errorText.style?.color, AppColors.light.destructive);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('辅助文案使用弱化色', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppFormItem(
          label: '日期区间',
          helper: '点击整项打开日历',
          child: AppFormDateRangeField(),
        ),
      ),
    );

    final helper = tester.widget<Text>(find.text('点击整项打开日历'));
    expect(helper.style?.color, AppColors.light.mutedForeground);
  });

  testWidgets('自定义 labelWidth 对齐任意 child 和外部错误', (tester) async {
    const childKey = ValueKey('custom child');
    await tester.pumpWidget(
      _buildTestApp(
        const SizedBox(
          width: 500,
          child: AppFormItem(
            label: '自定义标签',
            layout: AppFormItemLayout.left,
            labelWidth: 120,
            errorText: '错误提示',
            child: SizedBox(key: childKey, height: 52),
          ),
        ),
      ),
    );
    final itemLeft = tester.getTopLeft(find.byType(AppFormItem)).dx;
    final childLeft = tester.getTopLeft(find.byKey(childKey)).dx;
    expect(childLeft - itemLeft, 120 + AppSpacing.md);
    expect(
      tester.getTopLeft(find.byIcon(Icons.error_outline_rounded)).dx,
      childLeft,
    );
  });

  for (final size in [(width: 240.0, scale: 1.0), (width: 500.0, scale: 2.0)]) {
    testWidgets('左标签在宽 ${size.width} 字号 ${size.scale} 时自动切上方', (tester) async {
      const childKey = ValueKey('responsive child');
      await tester.pumpWidget(
        _buildTestApp(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(size.scale)),
            child: SizedBox(
              width: size.width,
              child: const AppFormItem(
                label: '可读标签',
                layout: AppFormItemLayout.left,
                errorText: '错误提示',
                child: SizedBox(
                  key: childKey,
                  width: double.infinity,
                  height: 52,
                ),
              ),
            ),
          ),
        ),
      );
      final label = tester.getRect(find.text('可读标签'));
      final child = tester.getRect(find.byKey(childKey));
      expect(child.top, greaterThan(label.bottom));
      expect(child.left, label.left);
      expect(
        tester.getTopLeft(find.byIcon(Icons.error_outline_rounded)).dx,
        child.left,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('左侧标签控件区从 88 宽标签列之后开始且行高不低于 52', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppFormItem(
          layout: AppFormItemLayout.left,
          label: '姓名',
          required: true,
          child: AppPickerField(filled: false, value: '林溪'),
        ),
      ),
    );

    // 标签列为固定 88 宽的 SizedBox。
    expect(
      tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .any((w) => w.width == 88),
      isTrue,
    );

    // 控件值从标签列之后开始（不受必填星号影响，以表单项左缘为基准）。
    final itemLeft = tester.getTopLeft(find.byType(Column).first);
    final valueLeft = tester.getTopLeft(find.text('林溪'));
    expect(valueLeft.dx - itemLeft.dx, greaterThanOrEqualTo(88));

    final rowSize = tester.getSize(find.byType(Row).first);
    expect(rowSize.height, greaterThanOrEqualTo(52));
  });

  testWidgets('左侧标签错误文案缩进对齐控件区', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppFormItem(
          layout: AppFormItemLayout.left,
          label: '手机号',
          errorText: '请输入11位手机号',
          child: AppPickerField(filled: false, value: '138'),
        ),
      ),
    );

    final labelLeft = tester.getTopLeft(find.text('手机号'));
    final errorLeft = tester.getTopLeft(find.text('请输入11位手机号'));
    expect(errorLeft.dx - labelLeft.dx, greaterThanOrEqualTo(88));
  });

  testWidgets('分组卡片 muted 填充、圆角 16 且无分割线', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppFormCard(
          children: [
            AppFormItem(
              layout: AppFormItemLayout.left,
              label: '姓名',
              child: AppPickerField(filled: false, value: '林溪'),
            ),
            AppFormItem(
              layout: AppFormItemLayout.left,
              label: '所在地区',
              child: AppPickerField(filled: false, value: '浙江省'),
            ),
          ],
        ),
      ),
    );

    final card = _materialOf(tester, find.byType(AppFormCard));
    expect(card.color, AppColors.light.muted);
    final radius = card.borderRadius as BorderRadius;
    expect(radius.topLeft, const Radius.circular(AppRadius.lg));
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('暗色主题下卡片使用暗色 muted 填充', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppFormCard(children: [SizedBox(height: 8)]),
        theme: AppTheme.dark,
      ),
    );

    final card = _materialOf(tester, find.byType(AppFormCard));
    expect(card.color, AppColors.dark.muted);
  });

  testWidgets('字段渲染已选值与箭头并响应点击', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _buildTestApp(
        AppPickerField(value: '浙江省 · 杭州市 · 西湖区', onTap: () => tapped++),
      ),
    );

    expect(find.text('浙江省 · 杭州市 · 西湖区'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.text('浙江省 · 杭州市 · 西湖区'));
    expect(tapped, 1);
  });

  testWidgets('只读平铺行不显示箭头且不自带填充盒', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppPickerField(filled: false, value: '138 0013 8000'),
      ),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppPickerField),
        matching: find.byType(Material),
      ),
      findsNothing,
    );
  });

  testWidgets('平铺字段错误态无新增 Material 且只显示一次错误', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _buildTestApp(
        const AppFormItem(
          label: '地区',
          child: AppPickerField(filled: false, errorText: '必选地区'),
        ),
      ),
    );
    final scope = find.byType(AppPickerField);
    expect(
      find.descendant(of: scope, matching: find.byType(Material)),
      findsNothing,
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: scope, matching: find.byType(DecoratedBox)),
    );
    final border = (box.decoration as BoxDecoration).border! as Border;
    expect(border.top.color, AppColors.light.destructive);
    expect(border.top.width, 2);
    expect(find.text('必选地区'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.text('必选地区'))
          .getSemanticsData()
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('空错误不触发错误态且 trailing 支持任意 Widget', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppPickerField(
          value: '杭州',
          errorText: '',
          trailing: Text('自定义尾随'),
        ),
      ),
    );
    expect(find.text('自定义尾随'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    final material = _materialOf(tester, find.byType(AppPickerField));
    expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
  });

  testWidgets('字段错误态使用 2px 危险色描边', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppPickerField(value: '138', errorText: '格式错误', onTap: _noop),
      ),
    );

    final material = _materialOf(tester, find.byType(AppPickerField));
    final shape = material.shape as RoundedRectangleBorder;
    expect(shape.side.color, AppColors.light.destructive);
    expect(shape.side.width, 2);
  });

  testWidgets('禁用字段值弱化且不响应点击', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _buildTestApp(
        AppPickerField(
          value: '不可编辑',
          enabled: false,
          trailing: const Icon(Icons.lock_outline_rounded),
          onTap: () => tapped++,
        ),
      ),
    );

    final value = tester.widget<Text>(find.text('不可编辑'));
    expect(value.style?.color, AppColors.light.mutedForeground);

    await tester.tap(find.text('不可编辑'), warnIfMissed: false);
    expect(tapped, 0);
  });

  testWidgets('日期区间字段渲染起止日期并可点击', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _buildTestApp(
        AppFormDateRangeField(
          range: (start: DateTime(2026, 9, 22), end: DateTime(2026, 9, 25)),
          onTap: () => tapped++,
        ),
      ),
    );

    expect(find.text('开始日期'), findsOneWidget);
    expect(find.text('结束日期'), findsOneWidget);
    expect(
      find.text(_materialL10n(tester).formatCompactDate(DateTime(2026, 9, 22))),
      findsOneWidget,
    );
    expect(
      find.text(_materialL10n(tester).formatCompactDate(DateTime(2026, 9, 25))),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    expect(tapped, 1);
  });

  testWidgets('未选择时展示占位且盒子使用 muted 填充', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(const AppFormDateRangeField(), theme: AppTheme.dark),
    );

    expect(find.text('选择日期'), findsNWidgets(2));

    final boxes = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(AppFormDateRangeField),
            matching: find.byType(Material),
          ),
        )
        .where((m) => m.color != Colors.transparent)
        .toList();
    expect(boxes.length, 2);
    expect(boxes.every((m) => m.color == AppColors.dark.muted), isTrue);
  });

  testWidgets('日期区间错误态两盒均带危险色描边', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppFormDateRangeField(errorText: '请选择区间', onTap: _noop),
      ),
    );

    final errorSides = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(AppFormDateRangeField),
            matching: find.byType(Material),
          ),
        )
        .map((m) => m.shape)
        .whereType<RoundedRectangleBorder>()
        .where((s) => s.side.color == AppColors.light.destructive)
        .toList();
    expect(errorSides.length, 2);
  });

  testWidgets('选择字段与日期区间支持语义点击', (tester) async {
    final semantics = tester.ensureSemantics();
    var tapped = 0;
    await tester.pumpWidget(
      _buildTestApp(
        Column(
          children: [
            AppPickerField(semanticLabel: '所在地区', onTap: () => tapped++),
            AppFormDateRangeField(onTap: () => tapped++),
          ],
        ),
      ),
    );

    for (final label in [
      '所在地区',
      _materialL10n(tester).dateRangePickerHelpText,
    ]) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
    }
    expect(tapped, 2);
    semantics.dispose();
  });

  testWidgets('窄屏左标签长地区不截断', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const SizedBox(
          width: 256,
          child: AppFormCard(
            children: [
              AppFormItem(
                label: '所在地区',
                layout: AppFormItemLayout.left,
                child: AppPickerField(
                  filled: false,
                  value: '浙江省 · 杭州市 · 西湖区',
                  onTap: _noop,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('浙江省 · 杭州市 · 西湖区'),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('zh'), const Locale('en')]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('$locale 窄屏日期区间在 $scale 倍字号下完整显示', (tester) async {
        final selected = (
          start: DateTime(2026, 1, 2),
          end: DateTime(2026, 12, 25),
        );
        await tester.pumpWidget(
          _buildTestApp(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: SizedBox(
                width: 256,
                child: AppFormDateRangeField(range: selected, onTap: _noop),
              ),
            ),
            locale: locale,
          ),
        );

        final context = tester.element(find.byType(AppFormDateRangeField));
        final l10n = AppLocalizations.of(context)!;
        final materialL10n = MaterialLocalizations.of(context);
        for (final text in [
          materialL10n.formatCompactDate(selected.start),
          materialL10n.formatCompactDate(selected.end),
          l10n.startDate,
          l10n.endDate,
        ]) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(text),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          );
          if (scale == 1) expect(boxes, hasLength(1));
          final fieldRect = tester.getRect(find.byType(AppFormDateRangeField));
          final textLeft = tester.getTopLeft(find.text(text)).dx;
          for (final box in boxes) {
            expect(textLeft + box.left, greaterThanOrEqualTo(fieldRect.left));
            expect(textLeft + box.right, lessThanOrEqualTo(fieldRect.right));
          }
        }
        expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final content in ['dates', 'placeholder', 'startLabel', 'endLabel']) {
    testWidgets('横排断点测量实际英文 $content 最长文本', (tester) async {
      final selected = (
        start: DateTime(2026, 1, 2),
        end: DateTime(2026, 12, 25),
      );
      Widget build(double width) => _buildTestApp(
        SizedBox(
          width: width,
          child: AppFormDateRangeField(
            range: content == 'placeholder' ? null : selected,
            startLabel: content == 'startLabel'
                ? 'Expected arrival date'
                : null,
            endLabel: content == 'endLabel' ? 'Expected departure date' : null,
          ),
        ),
        locale: const Locale('en'),
      );
      await tester.pumpWidget(build(800));
      var contentWidth = 0.0;
      final texts = find.descendant(
        of: find.byType(AppFormDateRangeField),
        matching: find.byType(Text),
      );
      for (final element in texts.evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        final width = paragraph.getMaxIntrinsicWidth(double.infinity);
        if (width > contentWidth) contentWidth = width;
      }
      final minWidth =
          (contentWidth.ceilToDouble() + AppSpacing.md * 2) * 2 +
          AppSpacing.sm * 2 +
          16;

      await tester.pumpWidget(build(minWidth - 1));
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(build(minWidth + 1));
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      for (final element in texts.evaluate()) {
        final paragraph = element.renderObject! as RenderParagraph;
        final text = (element.widget as Text).data!;
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          ),
          hasLength(1),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
