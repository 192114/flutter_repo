import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_dialog.dart';
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
  testWidgets('英文默认按钮随 locale 更新，自定义文案保持原样', (tester) async {
    const dialogs = Column(
      children: [
        AppAlertDialog(title: 'Alert'),
        AppConfirmDialog(title: 'Confirm action'),
      ],
    );
    await tester.pumpWidget(_buildTestApp(dialogs, locale: const Locale('en')));
    expect(find.text('Got it'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('知道了'), findsNothing);

    await tester.pumpWidget(_buildTestApp(dialogs));
    await tester.pumpAndSettle();
    expect(find.text('知道了'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);

    await tester.pumpWidget(
      _buildTestApp(
        const Column(
          children: [
            AppAlertDialog(title: 'Alert', confirmLabel: '已阅'),
            AppConfirmDialog(
              title: 'Confirm action',
              cancelLabel: '暂不',
              confirmLabel: '继续',
            ),
          ],
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('已阅'), findsOneWidget);
    expect(find.text('暂不'), findsOneWidget);
    expect(find.text('继续'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
  });

  testWidgets('提示弹窗渲染信息样式并触发确认回调', (tester) async {
    var didConfirm = false;

    await tester.pumpWidget(
      _buildTestApp(
        AppAlertDialog(
          title: '提示',
          message: '您的操作已完成，感谢使用。',
          onConfirm: () => didConfirm = true,
        ),
      ),
    );

    expect(find.text('提示'), findsOneWidget);
    expect(find.text('您的操作已完成，感谢使用。'), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);
    expect(tester.widget<Text>(find.text('提示')).textAlign, TextAlign.center);
    expect(
      tester.widget<Text>(find.text('您的操作已完成，感谢使用。')).textAlign,
      TextAlign.center,
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
    expect(icon.color, AppColors.light.info);

    await tester.tap(find.text('知道了'));
    expect(didConfirm, isTrue);
  });

  testWidgets('确认弹窗提供取消和危险确认操作', (tester) async {
    var didCancel = false;
    var didConfirm = false;

    await tester.pumpWidget(
      _buildTestApp(
        AppConfirmDialog(
          title: '删除确认',
          message: '删除后无法恢复，确定要删除此内容吗？',
          intent: AppDialogIntent.destructive,
          confirmLabel: '确认删除',
          onCancel: () => didCancel = true,
          onConfirm: () => didConfirm = true,
        ),
      ),
    );

    expect(find.text('删除确认'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确认删除'), findsOneWidget);

    final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    expect(icon.color, AppColors.light.destructive);
    expect(tester.widget<Text>(find.text('删除确认')).textAlign, TextAlign.center);
    expect(
      tester.widget<Text>(find.text('删除后无法恢复，确定要删除此内容吗？')).textAlign,
      TextAlign.center,
    );

    await tester.tap(find.text('取消'));
    await tester.tap(find.text('确认删除'));
    expect(didCancel, isTrue);
    expect(didConfirm, isTrue);
  });

  testWidgets('确认弹窗辅助方法返回用户的确认结果', (tester) async {
    late Future<bool?> result;

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => result = AppDialogs.showConfirm(
              context,
              title: '删除确认',
              message: '删除后无法恢复，确定要删除此内容吗？',
              intent: AppDialogIntent.destructive,
              confirmLabel: '确认删除',
            ),
            child: const Text('打开确认弹窗'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开确认弹窗'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(find.text('删除确认'), findsNothing);
  });

  testWidgets('默认确认采用普通 intent 和确定文案', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(AppConfirmDialog(title: '继续操作', onConfirm: () {})),
    );
    expect(find.text('确定'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.info_outline)).color,
      AppColors.light.primary,
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style?.backgroundColor?.resolve({}), AppColors.light.primary);
    expect(
      button.style?.foregroundColor?.resolve({}),
      AppColors.light.primaryForeground,
    );
  });

  for (final exit in ['确定', '取消', 'barrier', 'back']) {
    testWidgets('确认辅助方法正确返回 $exit 退出结果', (tester) async {
      late Future<bool?> result;
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => FilledButton(
              onPressed: () => result = AppDialogs.showConfirm(
                context,
                title: '退出测试',
                content: const Text('自定义内容'),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      expect(find.text('自定义内容'), findsOneWidget);
      switch (exit) {
        case 'barrier':
          await tester.tapAt(const Offset(5, 5));
        case 'back':
          await tester.binding.handlePopRoute();
        default:
          await tester.tap(find.text(exit));
      }
      await tester.pumpAndSettle();
      expect(await result, switch (exit) {
        '确定' => true,
        '取消' => false,
        _ => null,
      });
      expect(find.text('退出测试'), findsNothing);
      expect(find.text('打开'), findsOneWidget);
    });
  }

  testWidgets('禁用遮罩关闭后点击遮罩不退出', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              await AppDialogs.showConfirm(
                context,
                title: '必须选择',
                barrierDismissible: false,
              );
              completed = true;
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(completed, isFalse);
    expect(find.text('必须选择'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('提示辅助方法接受自定义内容且重复确认不退出底层页面', (tester) async {
    var completed = false;
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              await AppDialogs.showAlert(
                context,
                title: '提示内容',
                content: const Text('可替换内容'),
              );
              completed = true;
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('可替换内容'), findsOneWidget);
    final callback = tester
        .widget<AppAlertDialog>(find.byType(AppAlertDialog))
        .onConfirm!;
    callback();
    callback();
    await tester.pumpAndSettle();
    callback();
    expect(completed, isTrue);
    expect(find.text('提示内容'), findsNothing);
    expect(find.text('打开'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('长自定义内容可滚动且不挤出操作按钮', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        AppConfirmDialog(
          title: '长内容',
          content: Column(
            children: [for (var i = 0; i < 40; i++) Text('内容 $i')],
          ),
          onConfirm: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('确定').hitTestable(), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -1000),
    );
    await tester.pumpAndSettle();
    expect(find.text('内容 39').hitTestable(), findsOneWidget);
  });

  test('message 与 content 不能同时指定', () {
    expect(
      () => AppConfirmDialog(
        title: '冲突',
        message: '文案',
        content: const Text('内容'),
      ),
      throwsAssertionError,
    );
    expect(
      () =>
          AppAlertDialog(title: '冲突', message: '文案', content: const Text('内容')),
      throwsAssertionError,
    );
  });
}
