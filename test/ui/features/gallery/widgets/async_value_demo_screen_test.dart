import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/features/gallery/widgets/async_value_demo_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp() => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('zh'),
  theme: AppTheme.light,
  home: const AsyncValueDemoScreen(),
);

void main() {
  testWidgets('三态切换：成功 → 失败 → 重试恢复 → 加载中', (tester) async {
    await tester.pumpWidget(_buildTestApp());

    expect(find.text('数据加载成功'), findsOneWidget);
    expect(find.text('共 42 条记录，耗时 128ms'), findsOneWidget);

    await tester.tap(find.text('失败'));
    await tester.pump();
    expect(find.text('加载失败，请稍后重试'), findsOneWidget);
    expect(find.text('网络请求失败（模拟）'), findsNothing);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(find.text('数据加载成功'), findsOneWidget);

    await tester.tap(find.text('加载中'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('数据加载成功'), findsNothing);
  });
}
