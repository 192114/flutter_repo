import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/features/gallery/widgets/form_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: const FormDemoScreen(),
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
  testWidgets('演示页展示全部表单组件分区', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    expect(find.text('表单组件演示'), findsOneWidget);
    expect(find.text('按钮'), findsOneWidget);
    expect(find.text('输入'), findsOneWidget);

    await _scrollTo(tester, find.text('选择控件'));
    expect(find.text('选择控件'), findsOneWidget);

    await _scrollTo(tester, find.byKey(const Key('field-city')));
    expect(find.text('选择器与日期'), findsOneWidget);
    expect(find.byKey(const Key('field-date')), findsOneWidget);
    expect(find.byKey(const Key('field-time')), findsOneWidget);
  });

  testWidgets('选择城市后选择行展示选中值', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _scrollTo(tester, find.byKey(const Key('field-city')));
    await tester.tap(find.byKey(const Key('field-city')));
    await tester.pumpAndSettle();
    expect(find.text('请选择城市'), findsOneWidget);

    await tester.tap(find.text('上海'));
    await tester.pumpAndSettle();
    expect(find.text('上海'), findsOneWidget);
    expect(find.text('请选择城市'), findsNothing);
  });

  testWidgets('选择日期后选择行展示格式化日期', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _scrollTo(tester, find.byKey(const Key('field-date')));
    await tester.tap(find.byKey(const Key('field-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final expected =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    expect(find.text(expected), findsOneWidget);
  });

  testWidgets('单选与开关可交互切换', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _scrollTo(tester, find.byKey(const Key('radio-1')));
    await tester.tap(find.byKey(const Key('radio-1')));
    await tester.pumpAndSettle();
    // 点击不崩溃且保持单选组渲染。
    expect(find.text('选项二'), findsOneWidget);

    await tester.tap(find.text('深色模式'));
    await tester.pumpAndSettle();
    expect(find.text('深色模式'), findsOneWidget);
  });

  testWidgets('提交按钮进入加载态后恢复', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    // 页面下方还有「表单排版」分区的提交按钮，断言按 key 收敛作用域。
    final submit = find.byKey(const Key('form-submit'));
    await tester.tap(submit);
    await tester.pump();
    expect(
      find.descendant(of: submit, matching: find.text('提交中')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: submit, matching: find.text('提交')),
      findsOneWidget,
    );
  });

  testWidgets('密码框后缀图标切换明文密文', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    final passwordField = find.byKey(const Key('input-password'));
    await _scrollTo(tester, passwordField);

    TextField field = tester.widget(
      find.descendant(of: passwordField, matching: find.byType(TextField)),
    );
    expect(field.obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    field = tester.widget(
      find.descendant(of: passwordField, matching: find.byType(TextField)),
    );
    expect(field.obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('表单排版：地区选择联动卡片行与填充字段', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _scrollTo(tester, find.byKey(const Key('form-row-region')));
    await tester.tap(find.byKey(const Key('form-row-region')));
    await tester.pumpAndSettle();
    expect(find.text('请选择所在地区'), findsOneWidget);

    await tester.tap(find.text('广东省 · 深圳市 · 南山区'));
    await tester.pumpAndSettle();
    expect(find.text('广东省 · 深圳市 · 南山区'), findsWidgets);

    await _scrollTo(tester, find.byKey(const Key('form-field-region')));
    expect(find.text('广东省 · 深圳市 · 南山区'), findsWidgets);
  });

  testWidgets('表单排版：手机号校验失败展示错误文案', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    final phoneInput = find.byKey(const Key('form-input-phone'));
    await _scrollTo(tester, phoneInput);
    await tester.enterText(
      find.descendant(of: phoneInput, matching: find.byType(TextField)),
      '138',
    );
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.byKey(const Key('form-layout-submit')));
    await tester.tap(find.byKey(const Key('form-layout-submit')));
    await tester.pumpAndSettle();

    expect(find.text('请输入11位手机号'), findsOneWidget);
  });

  testWidgets('表单重置清除输入和校验错误', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    final phone = find.descendant(
      of: find.byKey(const Key('form-input-phone')),
      matching: find.byType(TextField),
    );
    await _scrollTo(tester, phone);
    await tester.enterText(phone, '138');
    await tester.pumpAndSettle();
    expect(find.text('请输入11位手机号'), findsOneWidget);

    final reset = find.byKey(const Key('form-layout-reset'));
    await _scrollTo(tester, reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(find.text('请输入11位手机号'), findsNothing);
    await _scrollTo(tester, phone);
    expect(tester.widget<TextField>(phone).controller!.text, isEmpty);
  });

  testWidgets('表单排版：日期区间字段弹出日历并可取消', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await _scrollTo(tester, find.byKey(const Key('form-field-range')));
    await tester.tap(find.byKey(const Key('form-field-range')));
    await tester.pumpAndSettle();

    expect(find.text('取消'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('取消'), findsNothing);
    expect(find.text('选择日期'), findsNWidgets(2));
  });
}
