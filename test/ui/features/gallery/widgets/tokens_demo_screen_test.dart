import 'package:flutter/material.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/features/gallery/widgets/tokens_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp() =>
    MaterialApp(theme: AppTheme.light, home: const TokensDemoScreen());

void main() {
  testWidgets('展示颜色、圆角与间距 token', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    expect(find.text('颜色'), findsOneWidget);
    expect(find.text('圆角'), findsOneWidget);

    // 语义色卡：名称 + 当前主题下的 hex 值（primary 与 ring 同值，允许多个）。
    expect(find.text('primary'), findsOneWidget);
    expect(find.text('#465BF0'), findsWidgets);
    expect(find.text('destructive'), findsOneWidget);
    expect(find.text('#D11F1F'), findsOneWidget);

    // 间距分区位于首屏下方，需滚动后断言。
    await tester.scrollUntilVisible(find.text('间距'), 200);
    expect(find.text('间距'), findsOneWidget);
    expect(find.text('xxxl · 32'), findsOneWidget);
  });
}
