import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_input.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(Widget child) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

InputDecoration _decorationOf(WidgetTester tester) {
  final field = tester.widget<TextField>(find.byType(TextField));
  return field.decoration!;
}

void main() {
  test('输入参数互斥与行数长度断言', () {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    expect(
      () => AppInput(controller: controller, initialValue: '冲突'),
      throwsAssertionError,
    );
    expect(
      () => AppInput(prefix: const Text('前'), prefixIcon: Icons.search),
      throwsAssertionError,
    );
    expect(
      () => AppInput(suffix: const Text('后'), suffixIcon: Icons.clear),
      throwsAssertionError,
    );
    expect(() => AppInput(maxLines: 0), throwsAssertionError);
    expect(() => AppInput(minLines: 0), throwsAssertionError);
    expect(() => AppInput(minLines: 2), throwsAssertionError);
    expect(
      () => AppInput(obscureText: true, maxLines: 2),
      throwsAssertionError,
    );
    expect(() => AppInput(maxLength: 0), throwsAssertionError);
    expect(() => AppInput(maxLength: -2), throwsAssertionError);
    expect(() => AppInput(maxLength: TextField.noMaxLength), returnsNormally);
  });

  testWidgets('输入框接入 Form 校验、保存、重置', (tester) async {
    final form = GlobalKey<FormState>();
    String? saved;
    await tester.pumpWidget(
      _buildTestApp(
        Form(
          key: form,
          child: AppInput(
            initialValue: '初值',
            validator: (value) =>
                value == null || value.isEmpty ? '不能为空' : null,
            onSaved: (value) => saved = value,
          ),
        ),
      ),
    );
    expect(find.text('初值'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('不能为空'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '新值');
    expect(form.currentState!.validate(), isTrue);
    form.currentState!.save();
    expect(saved, '新值');
    form.currentState!.reset();
    await tester.pump();
    expect(find.text('初值'), findsOneWidget);
    expect(find.text('不能为空'), findsNothing);
    form.currentState!.save();
    expect(saved, '初值');
  });

  testWidgets('外部错误覆盖 validator 并参与 Form 有效性', (tester) async {
    final form = GlobalKey<FormState>();
    var validations = 0;
    Widget build(String? error) => _buildTestApp(
      Form(
        key: form,
        child: AppInput(
          initialValue: 'abc',
          errorText: error,
          validator: (_) {
            validations++;
            return '本地错误';
          },
        ),
      ),
    );
    await tester.pumpWidget(build('外部错误'));
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(validations, 0);
    expect(find.text('外部错误'), findsOneWidget);
    expect(find.text('本地错误'), findsNothing);
    await tester.pumpWidget(build(''));
    expect(find.text('外部错误'), findsNothing);
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(validations, 1);
    expect(find.text('本地错误'), findsOneWidget);
  });

  testWidgets('controller 外部更新与替换同步到 Form，reset 使用初始文本', (tester) async {
    final form = GlobalKey<FormState>();
    final first = TextEditingController(text: '初值');
    final second = TextEditingController(text: '替换值');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    String? saved;
    Widget build(TextEditingController controller) => _buildTestApp(
      Form(
        key: form,
        child: AppInput(
          controller: controller,
          onSaved: (value) => saved = value,
        ),
      ),
    );
    await tester.pumpWidget(build(first));
    first.text = '外部更新';
    await tester.pump();
    form.currentState!.save();
    expect(saved, '外部更新');
    expect(find.text('外部更新'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '用户输入');
    expect(first.text, '用户输入');
    form.currentState!.reset();
    await tester.pump();
    expect(first.text, '初值');
    await tester.pumpWidget(build(second));
    form.currentState!.save();
    expect(saved, '替换值');
    first.text = '旧控制器';
    await tester.pump();
    expect(find.text('替换值'), findsOneWidget);
    expect(find.text('旧控制器'), findsNothing);
  });

  testWidgets('只读保留值、焦点和保存能力且不打开输入连接', (tester) async {
    final form = GlobalKey<FormState>();
    final focus = FocusNode();
    addTearDown(focus.dispose);
    String? saved;
    await tester.pumpWidget(
      _buildTestApp(
        Form(
          key: form,
          child: AppInput(
            initialValue: '只读文本',
            readOnly: true,
            focusNode: focus,
            onSaved: (value) => saved = value,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(focus.hasFocus, isTrue);
    expect(tester.testTextInput.hasAnyClients, isFalse);
    form.currentState!.save();
    expect(saved, '只读文本');
  });

  testWidgets('formatters、maxLength、autofillHints、minLines 和输入动作生效', (
    tester,
  ) async {
    final submitted = <String>[];
    final changed = <String>[];
    await tester.pumpWidget(
      _buildTestApp(
        AppInput(
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 4,
          minLines: 1,
          autofillHints: const [AutofillHints.telephoneNumber],
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.search,
          onSubmitted: submitted.add,
          onChanged: changed.add,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'a123456');
    expect(find.text('1234'), findsOneWidget);
    expect(changed, ['1234']);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 1);
    expect(field.maxLength, 4);
    expect(field.keyboardType, TextInputType.phone);
    expect(field.autofillHints, [AutofillHints.telephoneNumber]);
    expect(field.textInputAction, TextInputAction.search);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submitted, ['1234']);
  });

  testWidgets('交互后自动校验并支持任意前后缀 Widget', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        AppInput(
          prefix: const Text('前缀'),
          suffix: const Text('后缀'),
          validator: (value) => value == 'ok' ? null : '输入 ok',
          autovalidateMode: AutovalidateMode.onUserInteraction,
        ),
      ),
    );
    expect(find.text('前缀'), findsOneWidget);
    expect(find.text('后缀'), findsOneWidget);
    expect(find.text('输入 ok'), findsNothing);
    await tester.enterText(find.byType(TextField), 'no');
    await tester.pump();
    expect(find.text('输入 ok'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ok');
    await tester.pump();
    expect(find.text('输入 ok'), findsNothing);
  });

  testWidgets('可点图标有 48 点击区、tooltip 与语义标签', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _buildTestApp(
        AppInput(
          prefixIcon: Icons.search,
          suffixIcon: Icons.clear,
          prefixIconTooltip: '搜索提示',
          suffixIconTooltip: '清除提示',
          prefixIconSemanticLabel: '搜索输入',
          suffixIconSemanticLabel: '清除输入',
          onPrefixIconPressed: () => tapped++,
          onSuffixIconPressed: () => tapped++,
        ),
      ),
    );
    expect(find.byTooltip('搜索提示'), findsOneWidget);
    expect(find.byTooltip('清除提示'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.search)).semanticLabel,
      '搜索输入',
    );
    expect(tester.widget<Icon>(find.byIcon(Icons.clear)).semanticLabel, '清除输入');
    for (final button in find.byType(IconButton).evaluate()) {
      final size = tester.getSize(find.byWidget(button.widget));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byWidget(button.widget));
    }
    expect(tapped, 2);
  });

  testWidgets('渲染标签与占位文案，可输入文本', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(const AppInput(label: '用户名', hint: '请输入用户名')),
    );

    expect(find.text('用户名'), findsOneWidget);
    expect(find.text('请输入用户名'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'shadow');
    expect(find.text('shadow'), findsOneWidget);
  });

  testWidgets('错误态展示错误文案并使用危险色边框', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppInput(label: '验证码', hint: '请输入', errorText: '验证码不正确'),
      ),
    );

    expect(find.text('验证码不正确'), findsOneWidget);
    final errorText = tester.widget<Text>(find.text('验证码不正确'));
    expect(errorText.style?.color, AppColors.light.destructive);

    final decoration = _decorationOf(tester);
    final border = decoration.focusedBorder! as OutlineInputBorder;
    expect(border.borderSide.color, AppColors.light.destructive);
    expect(border.borderSide.width, 2);
  });

  testWidgets('聚焦态使用主色 2px 边框', (tester) async {
    await tester.pumpWidget(_buildTestApp(const AppInput(hint: '请输入')));

    final decoration = _decorationOf(tester);
    final border = decoration.focusedBorder! as OutlineInputBorder;
    expect(border.borderSide.color, AppColors.light.ring);
    expect(border.borderSide.width, 2);
  });

  testWidgets('填充式使用 muted 底且默认无边框', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(const AppInput(hint: '请输入姓名', filled: true)),
    );

    final decoration = _decorationOf(tester);
    expect(decoration.fillColor, AppColors.light.muted);
    final border = decoration.enabledBorder! as OutlineInputBorder;
    expect(border.borderSide, BorderSide.none);

    final focused = decoration.focusedBorder! as OutlineInputBorder;
    expect(focused.borderSide.color, AppColors.light.ring);
    expect(focused.borderSide.width, 2);
  });

  testWidgets('填充式错误态仍显示 2px 危险色边框', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppInput(hint: '请输入', filled: true, errorText: '格式不正确'),
      ),
    );

    final decoration = _decorationOf(tester);
    final border = decoration.enabledBorder! as OutlineInputBorder;
    expect(border.borderSide.color, AppColors.light.destructive);
    expect(border.borderSide.width, 2);
  });

  testWidgets('禁用态使用弱化填充且不可编辑', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(const AppInput(label: '邀请码', hint: '不可编辑', enabled: false)),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);

    final decoration = _decorationOf(tester);
    expect(decoration.fillColor, AppColors.light.muted);

    await tester.enterText(find.byType(TextField), 'abc');
    expect(find.text('abc'), findsNothing);
  });

  testWidgets('暗色主题下边框与填充使用暗色 token', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: AppInput(label: '用户名', hint: '请输入用户名'),
          ),
        ),
      ),
    );

    final decoration = _decorationOf(tester);
    expect(decoration.fillColor, AppColors.dark.card);
    final border = decoration.enabledBorder! as OutlineInputBorder;
    expect(border.borderSide.color, AppColors.dark.input);
  });

  testWidgets('多行模式支持多行输入', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(const AppInput(label: '备注', hint: '请输入备注', maxLines: 4)),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLines, 4);
  });

  testWidgets('渲染前后图标，尺寸 20 且使用弱化色', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppInput(
          hint: '请输入',
          prefixIcon: Icons.search_rounded,
          suffixIcon: Icons.mic_none_rounded,
        ),
      ),
    );

    final prefix = tester.widget<Icon>(find.byIcon(Icons.search_rounded));
    expect(prefix.size, 20);
    expect(prefix.color, AppColors.light.mutedForeground);

    final suffix = tester.widget<Icon>(find.byIcon(Icons.mic_none_rounded));
    expect(suffix.size, 20);
    expect(suffix.color, AppColors.light.mutedForeground);
  });

  testWidgets('后缀图标点击触发回调', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _buildTestApp(
        AppInput(
          hint: '请输入密码',
          suffixIcon: Icons.visibility_off_outlined,
          onSuffixIconPressed: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    expect(tapped, 1);
  });

  testWidgets('禁用态图标不响应点击', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _buildTestApp(
        AppInput(
          hint: '不可编辑',
          enabled: false,
          suffixIcon: Icons.lock_outline_rounded,
          onSuffixIconPressed: () => tapped++,
        ),
      ),
    );

    // 禁用态不存在可点的手势目标，命中警告符合预期。
    await tester.tap(
      find.byIcon(Icons.lock_outline_rounded),
      warnIfMissed: false,
    );
    expect(tapped, 0);
  });
}
