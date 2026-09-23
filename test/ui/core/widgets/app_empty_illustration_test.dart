import 'package:flutter/material.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_empty.dart';
import 'package:flutter_repo/ui/core/widgets/app_empty_illustration.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(
  Widget child, {
  ThemeMode themeMode = ThemeMode.light,
  ThemeData? theme,
}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: themeMode,
  home: Scaffold(body: Center(child: child)),
);

CustomPainter _painterOf(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.descendant(
        of: find.byType(AppEmptyIllustration),
        matching: find.byType(CustomPaint),
      ),
    )
    .painter!;

void main() {
  for (final type in AppEmptyIllustrationType.values) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${type.name} 在 ${mode.name} 主题及不同尺寸下绘制无异常', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(AppEmptyIllustration(type: type), themeMode: mode),
        );
        expect(find.byType(AppEmptyIllustration), findsOneWidget);
        expect(
          tester.getSize(find.byType(AppEmptyIllustration)),
          const Size.square(96),
        );
        expect(tester.takeException(), isNull);

        for (final size in [const Size.square(40), const Size(160, 80)]) {
          await tester.pumpWidget(
            _buildTestApp(
              SizedBox.fromSize(
                size: size,
                child: AppEmptyIllustration(type: type),
              ),
              themeMode: mode,
            ),
          );
          expect(tester.getSize(find.byType(AppEmptyIllustration)), size);
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('${type.name} 可作为标准和 compact 的自定义图示', (tester) async {
      for (final compact in [false, true]) {
        await tester.pumpWidget(
          _buildTestApp(
            SizedBox(
              width: 320,
              child: AppEmpty(
                icon: AppEmptyIllustration(type: type),
                title: '暂无内容',
                compact: compact,
              ),
            ),
          ),
        );

        expect(find.text('暂无内容'), findsOneWidget);
        expect(
          tester.getSize(find.byType(AppEmptyIllustration)),
          Size.square(compact ? 40 : 96),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('${type.name} 相同输入不重绘，type 和主题变化需重绘', (tester) async {
      await tester.pumpWidget(_buildTestApp(AppEmptyIllustration(type: type)));
      final initial = _painterOf(tester);

      await tester.pumpWidget(_buildTestApp(AppEmptyIllustration(type: type)));
      final unchanged = _painterOf(tester);
      expect(unchanged, isNot(same(initial)));
      expect(unchanged.shouldRepaint(initial), isFalse);

      final types = AppEmptyIllustrationType.values;
      final nextType = types[(type.index + 1) % types.length];
      await tester.pumpWidget(
        _buildTestApp(AppEmptyIllustration(type: nextType)),
      );
      final changedType = _painterOf(tester);
      expect(changedType.shouldRepaint(unchanged), isTrue);

      await tester.pumpWidget(
        _buildTestApp(
          AppEmptyIllustration(type: nextType),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();
      final dark = _painterOf(tester);
      expect(dark.shouldRepaint(changedType), isTrue);

      await tester.pumpWidget(
        _buildTestApp(AppEmptyIllustration(type: nextType)),
      );
      await tester.pumpAndSettle();
      expect(_painterOf(tester).shouldRepaint(dark), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('亮度不变但 AppColors token 变化时仍需重绘', (tester) async {
    const illustration = AppEmptyIllustration(
      type: AppEmptyIllustrationType.content,
    );
    await tester.pumpWidget(_buildTestApp(illustration));
    final initial = _painterOf(tester);

    await tester.pumpWidget(
      _buildTestApp(
        illustration,
        theme: AppTheme.light.copyWith(
          extensions: [AppColors.light.copyWith(primary: Colors.purple)],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_painterOf(tester).shouldRepaint(initial), isTrue);
    expect(tester.takeException(), isNull);
  });
}
