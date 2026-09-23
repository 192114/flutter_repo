import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_toast.dart';
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
  testWidgets('英文轻提示状态语义本地化但保留调用方消息', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _buildTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final type in ToastType.values)
              FeedbackToast(message: '自定义消息', type: type),
          ],
        ),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('自定义消息'), findsNWidgets(4));
    for (final status in ['Success', 'Error', 'Warning', 'Loading']) {
      expect(find.bySemanticsLabel(RegExp('^$status: 自定义消息')), findsOneWidget);
    }
    semantics.dispose();
  });

  testWidgets('轻提示渲染四种反馈状态及对应图标', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeedbackToast(message: '操作成功', type: ToastType.success),
            FeedbackToast(message: '操作失败', type: ToastType.error),
            FeedbackToast(message: '请注意检查', type: ToastType.warning),
            FeedbackToast(message: '加载中…', type: ToastType.loading),
          ],
        ),
      ),
    );

    expect(find.text('操作成功'), findsOneWidget);
    expect(find.text('操作失败'), findsOneWidget);
    expect(find.text('请注意检查'), findsOneWidget);
    expect(find.text('加载中…'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final successIcon = tester.widget<Icon>(
      find.byIcon(Icons.check_circle_outline),
    );
    expect(successIcon.color, AppColors.light.success);
  });

  testWidgets('全局轻提示在到期后自动消失', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => AppToast.success(
              context,
              '保存成功',
              duration: const Duration(seconds: 1),
            ),
            child: const Text('保存'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('保存成功'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('保存成功'), findsNothing);
  });

  testWidgets('加载中轻提示可由控制器主动关闭', (tester) async {
    late ToastController controller;

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => controller = AppToast.loading(context, '正在提交'),
            child: const Text('提交'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('提交'));
    await tester.pump();
    expect(find.text('正在提交'), findsOneWidget);

    controller.dismiss();
    await tester.pump();
    expect(find.text('正在提交'), findsNothing);
  });

  testWidgets('连续展示两条提示时只保留最新一条（单槽替换）', (tester) async {
    late ToastController firstController;
    late ToastController secondController;

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => Column(
            children: [
              FilledButton(
                onPressed: () =>
                    firstController = AppToast.success(context, '第一条'),
                child: const Text('按钮一'),
              ),
              FilledButton(
                onPressed: () =>
                    secondController = AppToast.error(context, '第二条'),
                child: const Text('按钮二'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('按钮一'));
    await tester.pump();
    expect(find.text('第一条'), findsOneWidget);

    await tester.tap(find.text('按钮二'));
    await tester.pump();
    expect(find.text('第一条'), findsNothing);
    expect(find.text('第二条'), findsOneWidget);

    // 第一条已被单槽替换顶掉，控制器幂等 dismiss 不再影响第二条。
    firstController.dismiss();
    await tester.pump();
    expect(find.text('第二条'), findsOneWidget);

    secondController.dismiss();
    await tester.pump();
    expect(find.text('第二条'), findsNothing);
  });

  testWidgets('加载中轻提示超时后自动兜底消失', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () => AppToast.loading(context, '正在提交'),
            child: const Text('提交'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('提交'));
    await tester.pump();
    expect(find.text('正在提交'), findsOneWidget);

    // 30 秒兜底超时后自动消失，不会永久滞留。
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('正在提交'), findsNothing);
  });

  testWidgets('首帧前关闭会移除未挂载提示并取消定时器', (tester) async {
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

    final controller = AppToast.loading(context, '立即关闭');
    controller.dismiss();
    controller.dismiss();
    await tester.pump();
    expect(find.byType(FeedbackToast), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('同帧替换未挂载提示且旧控制器不会关闭新提示', (tester) async {
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

    final first = AppToast.loading(context, '第一条');
    final second = AppToast.success(context, '第二条');
    first.dismiss();
    await tester.pump();
    expect(find.text('第一条'), findsNothing);
    expect(find.text('第二条'), findsOneWidget);
    second.dismiss();
    await tester.pump();
    expect(find.byType(FeedbackToast), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading 支持自定义 duration', (tester) async {
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

    AppToast.loading(
      context,
      '短暂加载',
      duration: const Duration(milliseconds: 200),
    );
    await tester.pump();
    expect(find.text('短暂加载'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('短暂加载'), findsNothing);
  });
}
