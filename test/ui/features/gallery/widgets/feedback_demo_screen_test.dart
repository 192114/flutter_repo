import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_dialog.dart';
import 'package:flutter_repo/ui/features/gallery/widgets/feedback_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: const FeedbackDemoScreen(),
);

void main() {
  testWidgets('演示页展示全部反馈组件入口', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    expect(find.text('反馈组件演示'), findsOneWidget);
    expect(find.byKey(const Key('toast-success')), findsOneWidget);
    expect(find.byKey(const Key('toast-error')), findsOneWidget);
    expect(find.byKey(const Key('toast-warning')), findsOneWidget);
    expect(find.byKey(const Key('toast-loading')), findsOneWidget);
    expect(find.byKey(const Key('dialog-alert')), findsOneWidget);
    expect(find.byKey(const Key('dialog-confirm')), findsOneWidget);
  });

  testWidgets('演示页可实际唤起轻提示与两类弹窗', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    await tester.tap(find.byKey(const Key('toast-success')));
    await tester.pump();
    expect(find.text('操作成功'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.byKey(const Key('dialog-alert')));
    await tester.pumpAndSettle();
    expect(find.text('您的操作已完成，感谢使用。'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('删除后无法恢复，确定要删除此内容吗？'), findsOneWidget);
    final dialog = tester.widget<AppConfirmDialog>(
      find.byType(AppConfirmDialog),
    );
    expect(dialog.intent, AppDialogIntent.destructive);
    expect(dialog.confirmLabel, '确认删除');
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets('演示页加载提示按两秒自动关闭', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.tap(find.byKey(const Key('toast-loading')));
    await tester.pump();
    expect(find.text('加载中…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('加载中…'), findsNothing);
  });
}
