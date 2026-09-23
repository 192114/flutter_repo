import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
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

void main() {
  // 在测试体前创建，避免框架在 addTearDown 之前执行语义句柄泄漏检查。
  setUp(() {
    final handle = TestWidgetsFlutterBinding.ensureInitialized()
        .ensureSemantics();
    addTearDown(handle.dispose);
  });

  Future<void> openSelector(
    WidgetTester tester, {
    required List<AppSelectorOption<String>> options,
    String? initialValue,
    ValueChanged<String?>? onResult,
  }) async {
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              final result = await AppSelector.show<String>(
                context,
                title: '城市选项',
                options: options,
                initialValue: initialValue,
              );
              onResult?.call(result);
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
  }

  testWidgets('默认文案随语言切换，自定义操作和占位保持覆盖且大字无溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final content = SizedBox(
      width: 320,
      child: AppPickerSheet(
        title: 'Custom title',
        onCancel: () {},
        onConfirm: () {},
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSelectorField(label: 'City'),
            AppSelectorField(label: 'Area', placeholder: 'Custom hint'),
          ],
        ),
      ),
    );
    await tester.pumpWidget(_buildTestApp(content));
    expect(find.text('请选择'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
    await tester.pumpWidget(_buildTestApp(content, locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Please select'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Custom hint'), findsOneWidget);
    expect(find.text('Custom title'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      _buildTestApp(
        AppPickerSheet(
          title: 'Custom title',
          cancelLabel: 'Back',
          confirmLabel: 'Done',
          onCancel: () {},
          onConfirm: () {},
          child: const SizedBox(height: 80),
        ),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Confirm'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('英文空选项显示本地化空态并保留自定义标题', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => AppSelector.show<String>(
              context,
              title: 'Choose a city',
              options: const [],
            ),
            child: const Text('Open'),
          ),
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a city'), findsOneWidget);
    expect(find.text('No options'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('No options'), findsNothing);
  });

  testWidgets('空选项显示空态，关闭返回 null', (tester) async {
    String? result = '未关闭';
    await openSelector(
      tester,
      options: [],
      onResult: (value) => result = value,
    );
    expect(find.text('暂无可选项'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('禁用项没有语义点击动作，启用项可通过语义选中', (tester) async {
    String? result;
    await openSelector(
      tester,
      initialValue: '杭州',
      options: const [
        AppSelectorOption(label: '杭州', value: '杭州', enabled: false),
        AppSelectorOption(label: '上海', value: '上海'),
      ],
      onResult: (value) => result = value,
    );
    final disabled = tester.getSemantics(find.bySemanticsLabel('杭州'));
    expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
    expect(disabled.flagsCollection.isSelected, Tristate.isTrue);
    expect(disabled.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    await tester.tap(find.text('杭州'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('城市选项'), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('上海'));
    await tester.pumpAndSettle();
    expect(result, '上海');
  });

  testWidgets('缺失初值不选择任何项，重复选项值报错', (tester) async {
    await openSelector(
      tester,
      initialValue: '未知',
      options: const [AppSelectorOption(label: '杭州', value: '杭州')],
    );
    expect(find.byIcon(Icons.check), findsNothing);
    final context = tester.element(find.byType(AppPickerSheet));
    expect(
      () => AppSelector.show<String>(
        context,
        title: '重复',
        options: const [
          AppSelectorOption(label: '甲', value: 'same'),
          AppSelectorOption(label: '乙', value: 'same'),
        ],
      ),
      throwsArgumentError,
    );
  });

  testWidgets('取消与确定独立渲染，回调不会自动关闭壳', (tester) async {
    var cancels = 0;
    var confirms = 0;
    await tester.pumpWidget(
      _buildTestApp(
        AppPickerSheet(
          title: '仅取消',
          onCancel: () => cancels++,
          child: const SizedBox(height: 80),
        ),
      ),
    );
    expect(find.text('确定'), findsNothing);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(cancels, 1);
    expect(find.text('仅取消'), findsOneWidget);
    await tester.pumpWidget(
      _buildTestApp(
        AppPickerSheet(
          title: '仅确定',
          onConfirm: () => confirms++,
          child: const SizedBox(height: 80),
        ),
      ),
    );
    expect(find.text('取消'), findsNothing);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(confirms, 1);
    expect(find.text('仅确定'), findsOneWidget);
  });

  testWidgets('选择行外部清空回填，禁用与只读语义不响应点击', (tester) async {
    var taps = 0;
    Widget field(String? value, {bool enabled = true, bool readOnly = false}) =>
        _buildTestApp(
          AppSelectorField(
            label: '城市',
            value: value,
            enabled: enabled,
            onTap: readOnly ? null : () => taps++,
          ),
        );
    await tester.pumpWidget(field('杭州'));
    await tester.pumpWidget(field(null));
    expect(find.text('请选择'), findsOneWidget);
    await tester.pumpWidget(field('上海', enabled: false));
    expect(find.text('上海'), findsOneWidget);
    await tester.tap(find.text('城市'));
    expect(taps, 0);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('城市'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    await tester.pumpWidget(field('北京', readOnly: true));
    final node = tester.getSemantics(find.bySemanticsLabel('城市'));
    expect(node.flagsCollection.isReadOnly, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('滚轮受控回填与字号变化保持选项及滚动位置一致', (tester) async {
    var selected = 30;
    var scale = 1.0;
    var calls = 0;
    late StateSetter update;
    await tester.pumpWidget(
      _buildTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: AppPickerWheelGroup(
                children: [
                  AppPickerWheel(
                    items: List.generate(60, (index) => '$index'),
                    selectedIndex: selected,
                    onSelected: (index) {
                      calls++;
                      setState(() => selected = index);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(selected, isNot(30));
    update(() => selected = 45);
    await tester.pumpAndSettle();
    final before = calls;
    update(() => scale = 2);
    await tester.pumpAndSettle();
    final wheel = tester.widget<ListWheelScrollView>(
      find.byType(ListWheelScrollView),
    );
    expect(selected, 45);
    expect((wheel.controller! as FixedExtentScrollController).selectedItem, 45);
    expect(calls, before);
    expect(wheel.itemExtent, greaterThan(40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('大字选择行和长选项不溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      _buildTestApp(
        SizedBox(
          width: 320,
          child: AppSelectorField(
            label: '很长的城市名称',
            value: '很长的已选城市名称',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await openSelector(
      tester,
      options: const [
        AppSelectorOption(label: '这是一个很长的选项名称用于验证大字号下自动换行', value: 'a'),
      ],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('选择行展示标签与占位，选中后展示值', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const Column(
          children: [
            AppSelectorField(label: '城市'),
            AppSelectorField(label: '日期', value: '2026-09-20'),
          ],
        ),
      ),
    );

    expect(find.text('城市'), findsOneWidget);
    expect(find.text('请选择'), findsOneWidget);
    expect(find.text('2026-09-20'), findsOneWidget);
  });

  testWidgets('选择器弹出选项列表并返回选中值', (tester) async {
    String? result;

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await AppSelector.show<String>(
                context,
                title: '请选择城市',
                initialValue: '杭州',
                options: const [
                  AppSelectorOption(label: '杭州', value: '杭州'),
                  AppSelectorOption(label: '上海', value: '上海'),
                  AppSelectorOption(label: '北京', value: '北京'),
                ],
              );
            },
            child: const Text('打开选择器'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开选择器'));
    await tester.pumpAndSettle();

    expect(find.text('请选择城市'), findsOneWidget);
    expect(find.text('上海'), findsOneWidget);
    // 当前选中项行尾展示对勾。
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('上海'));
    await tester.pumpAndSettle();

    expect(result, '上海');
    expect(find.text('请选择城市'), findsNothing);
  });

  testWidgets('弹层操作行触发取消与确认回调', (tester) async {
    var didCancel = false;
    var didConfirm = false;

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => AppPickerSheet(
                title: '选择日期',
                onCancel: () {
                  didCancel = true;
                  Navigator.of(context).pop();
                },
                onConfirm: () {
                  didConfirm = true;
                  Navigator.of(context).pop();
                },
                child: const SizedBox(height: 120),
              ),
            ),
            child: const Text('打开弹层'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开弹层'));
    await tester.pumpAndSettle();

    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(didConfirm, isTrue);

    await tester.tap(find.text('打开弹层'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(didCancel, isTrue);
  });

  testWidgets('确认按钮可按 confirmEnabled 禁用', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => AppPickerSheet(
                title: '选择区间',
                onCancel: () => Navigator.of(context).pop(),
                onConfirm: () {},
                confirmEnabled: false,
                child: const SizedBox(height: 120),
              ),
            ),
            child: const Text('打开弹层'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开弹层'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('确定'), warnIfMissed: false);
    await tester.pumpAndSettle();
    // 禁用态点击不关闭弹层。
    expect(find.text('选择区间'), findsOneWidget);
  });
}
