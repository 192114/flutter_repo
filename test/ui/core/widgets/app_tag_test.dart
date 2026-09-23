import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_tag.dart';
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

Container _tagContainer(WidgetTester tester, String label) =>
    tester.widget<Container>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first,
    );

BoxDecoration _tagDecoration(WidgetTester tester, String label) =>
    _tagContainer(tester, label).decoration! as BoxDecoration;

void main() {
  testWidgets('英文删除提示保留自定义标签并触发关闭', (tester) async {
    var closed = 0;
    await tester.pumpWidget(
      _buildTestApp(
        AppTag(label: '园林', onClose: () => closed++),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('园林'), findsOneWidget);
    expect(find.byTooltip('Delete 园林'), findsOneWidget);
    expect(find.byTooltip('删除 园林'), findsNothing);
    await tester.tap(find.byTooltip('Delete 园林'));
    expect(closed, 1);
  });

  testWidgets('实心主要标签渲染文案并使用 primary 配色', (tester) async {
    await tester.pumpWidget(_buildTestApp(const AppTag(label: '主要')));

    expect(find.text('主要'), findsOneWidget);

    final decoration = _tagDecoration(tester, '主要');
    expect(decoration.color, AppColors.light.primary);
    expect(decoration.border, isNull);

    final text = tester.widget<Text>(find.text('主要'));
    expect(text.style?.color, AppColors.light.primaryForeground);
  });

  testWidgets('空心标签透明底加同色描边与文字', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(const AppTag(label: '主要', variant: AppTagVariant.outlined)),
    );

    final decoration = _tagDecoration(tester, '主要');
    expect(decoration.color, Colors.transparent);

    final border = decoration.border! as Border;
    expect(border.top.color, AppColors.light.primary);

    final text = tester.widget<Text>(find.text('主要'));
    expect(text.style?.color, AppColors.light.primary);
  });

  testWidgets('五语义色实心映射对应 token', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const Column(
          children: [
            AppTag(label: '成功', color: AppTagColor.success),
            AppTag(label: '警告', color: AppTagColor.warning),
            AppTag(label: '危险', color: AppTagColor.danger),
            AppTag(label: '默认', color: AppTagColor.normal),
          ],
        ),
      ),
    );

    expect(_tagDecoration(tester, '成功').color, AppColors.light.success);
    expect(_tagDecoration(tester, '警告').color, AppColors.light.warning);
    expect(_tagDecoration(tester, '危险').color, AppColors.light.destructive);
    expect(_tagDecoration(tester, '默认').color, AppColors.light.muted);

    expect(
      tester.widget<Text>(find.text('成功')).style?.color,
      AppColors.light.successForeground,
    );
    expect(
      tester.widget<Text>(find.text('警告')).style?.color,
      AppColors.light.warningForeground,
    );
    expect(
      tester.widget<Text>(find.text('危险')).style?.color,
      AppColors.light.destructiveForeground,
    );
    expect(
      tester.widget<Text>(find.text('默认')).style?.color,
      AppColors.light.secondaryForeground,
    );
  });

  testWidgets('空心默认色使用 input 描边与弱化文字', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppTag(
          label: '默认',
          variant: AppTagVariant.outlined,
          color: AppTagColor.normal,
        ),
      ),
    );

    final decoration = _tagDecoration(tester, '默认');
    final border = decoration.border! as Border;
    expect(border.top.color, AppColors.light.input);
    expect(
      tester.widget<Text>(find.text('默认')).style?.color,
      AppColors.light.mutedForeground,
    );
  });

  testWidgets('onClose 非空时展示关闭图标并触发回调', (tester) async {
    var closed = 0;

    await tester.pumpWidget(
      _buildTestApp(AppTag(label: '标签', onClose: () => closed++)),
    );

    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    expect(closed, 1);
  });

  testWidgets('onClose 为 null 时不展示关闭图标', (tester) async {
    await tester.pumpWidget(_buildTestApp(const AppTag(label: '标签')));

    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('暗色主题下使用暗色 token', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        theme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: Column(
              children: [
                AppTag(label: '主要'),
                AppTag(label: '成功', color: AppTagColor.success),
              ],
            ),
          ),
        ),
      ),
    );

    expect(_tagDecoration(tester, '主要').color, AppColors.dark.primary);
    expect(
      tester.widget<Text>(find.text('主要')).style?.color,
      AppColors.dark.primaryForeground,
    );
    expect(
      tester.widget<Text>(find.text('成功')).style?.color,
      AppColors.dark.successForeground,
    );
  });

  testWidgets('三档尺寸对应不同高度', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const Column(
          children: [
            AppTag(label: '小号', size: AppTagSize.small),
            AppTag(label: '中号'),
            AppTag(label: '大号', size: AppTagSize.large),
          ],
        ),
      ),
    );

    double heightOf(String label) => tester
        .getSize(
          find
              .ancestor(of: find.text(label), matching: find.byType(Container))
              .first,
        )
        .height;

    expect(heightOf('小号'), 24);
    expect(heightOf('中号'), 28);
    expect(heightOf('大号'), 32);
  });

  testWidgets('关闭按钮支持 Tab 聚焦与 Enter 和空格删除', (tester) async {
    var closed = 0;
    await tester.pumpWidget(
      _buildTestApp(AppTag(label: '键盘标签', onClose: () => closed++)),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(closed, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(closed, 2);
    expect(find.byTooltip('删除 键盘标签'), findsOneWidget);
  });

  for (final size in AppTagSize.values) {
    testWidgets('${size.name} 关闭按钮命中区48且不撑高视觉标签', (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        _buildTestApp(
          AppTag(label: '触控标签', size: size, onClose: () => closed++),
        ),
      );
      final tag = find
          .ancestor(of: find.text('触控标签'), matching: find.byType(Container))
          .first;
      final visual = tester.getRect(tag);
      final button = tester.getRect(find.byType(IconButton));
      final shell = tester.getRect(find.byType(AppTag));
      expect(visual.height, [24.0, 28.0, 32.0][size.index]);
      expect(button.size, const Size(48, 48));
      expect(shell.height, 48);
      expect(shell.contains(button.topLeft), isTrue);
      expect(shell.contains(button.bottomRight - const Offset(1, 1)), isTrue);
      expect(button.top, lessThan(visual.top));
      await tester.tapAt(button.topLeft + const Offset(2, 2));
      expect(closed, 1);
      await tester.tapAt(button.bottomRight - const Offset(2, 2));
      expect(closed, 2);
    });

    testWidgets('${size.name} 大字体自然增高不裁切且关闭按钮可用', (tester) async {
      var closed = 0;
      await tester.pumpWidget(
        _buildTestApp(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(4)),
            child: AppTag(label: '大字体', size: size, onClose: () => closed++),
          ),
        ),
      );
      final text = tester.getRect(find.text('大字体'));
      final tag = tester.getRect(
        find
            .ancestor(of: find.text('大字体'), matching: find.byType(Container))
            .first,
      );
      expect(tag.height, greaterThan([24.0, 28.0, 32.0][size.index]));
      expect(tag.top, lessThanOrEqualTo(text.top));
      expect(tag.bottom, greaterThanOrEqualTo(text.bottom));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, 1);
    });
  }
}
