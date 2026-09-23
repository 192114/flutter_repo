import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_button.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(Widget child) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('主按钮渲染文案并触发点击回调', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      _buildTestApp(AppButton(label: '主按钮', onPressed: () => tapped++)),
    );

    expect(find.text('主按钮'), findsOneWidget);

    await tester.tap(find.text('主按钮'));
    expect(tapped, 1);
  });

  testWidgets('禁用态不触发回调且使用弱化配色', (tester) async {
    await tester.pumpWidget(_buildTestApp(const AppButton(label: '禁用')));

    await tester.tap(find.text('禁用'), warnIfMissed: false);

    final text = tester.widget<Text>(find.text('禁用'));
    expect(text.style?.color, AppColors.light.mutedForeground);

    final material = tester.widget<Material>(
      find.ancestor(of: find.text('禁用'), matching: find.byType(Material)).first,
    );
    expect(material.color, AppColors.light.muted);
  });

  testWidgets('加载态展示进度指示并屏蔽点击', (tester) async {
    var tapped = 0;

    await tester.pumpWidget(
      _buildTestApp(
        AppButton(label: '加载中', loading: true, onPressed: () => tapped++),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('加载中'), warnIfMissed: false);
    expect(tapped, 0);
  });

  testWidgets('加载态保持变体配色，禁用态才转灰', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(AppButton(label: '提交中', loading: true, onPressed: () {})),
    );

    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text('提交中'), matching: find.byType(Material))
          .first,
    );
    expect(material.color, AppColors.light.primary);

    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.color, AppColors.light.primaryForeground);
  });

  testWidgets('文字变体禁用时背景保持透明', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppButton(label: '文字禁用', variant: AppButtonVariant.text),
      ),
    );

    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text('文字禁用'), matching: find.byType(Material))
          .first,
    );
    expect(material.color, Colors.transparent);

    final text = tester.widget<Text>(find.text('文字禁用'));
    expect(text.style?.color, AppColors.light.mutedForeground);
  });

  testWidgets('次要/描边/危险/文字变体使用对应 token 配色', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        Column(
          children: [
            AppButton(
              label: '次要',
              variant: AppButtonVariant.secondary,
              onPressed: () {},
            ),
            AppButton(
              label: '描边',
              variant: AppButtonVariant.outline,
              onPressed: () {},
            ),
            AppButton(
              label: '危险',
              variant: AppButtonVariant.destructive,
              onPressed: () {},
            ),
            AppButton(
              label: '文字',
              variant: AppButtonVariant.text,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    Material materialOf(String label) => tester.widget<Material>(
      find
          .ancestor(of: find.text(label), matching: find.byType(Material))
          .first,
    );

    expect(materialOf('次要').color, AppColors.light.secondary);
    expect(materialOf('描边').color, AppColors.light.card);
    expect(materialOf('危险').color, AppColors.light.destructive);
    expect(materialOf('文字').color, Colors.transparent);
  });

  testWidgets('暗色主题下主按钮使用暗色 token', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: AppButton(label: '主按钮', onPressed: () {}),
          ),
        ),
      ),
    );

    final material = tester.widget<Material>(
      find
          .ancestor(of: find.text('主按钮'), matching: find.byType(Material))
          .first,
    );
    expect(material.color, AppColors.dark.primary);

    final text = tester.widget<Text>(find.text('主按钮'));
    expect(text.style?.color, AppColors.dark.primaryForeground);
  });

  testWidgets('三档尺寸对应不同高度约束', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        Column(
          children: [
            AppButton(label: '大号', onPressed: () {}),
            AppButton(
              label: '中号',
              size: AppButtonSize.medium,
              onPressed: () {},
            ),
            AppButton(label: '小号', size: AppButtonSize.small, onPressed: () {}),
          ],
        ),
      ),
    );

    double heightOf(String label) => tester
        .getSize(
          find
              .ancestor(of: find.text(label), matching: find.byType(Material))
              .first,
        )
        .height;

    expect(heightOf('大号'), 44);
    expect(heightOf('中号'), 36);
    expect(heightOf('小号'), 28);
  });

  test('icon 与 leading 互斥，但均可搭配 trailing', () {
    expect(
      () => AppButton(
        label: '冲突',
        icon: Icons.add,
        leading: const Icon(Icons.star),
      ),
      throwsAssertionError,
    );
    expect(
      () => AppButton(
        label: '兼容',
        icon: Icons.add,
        trailing: const Icon(Icons.chevron_right),
      ),
      returnsNormally,
    );
  });

  testWidgets('leading/trailing 按顺序展示并继承前景色与图标尺寸', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        AppButton(
          label: '继续',
          onPressed: () {},
          leading: const Icon(Icons.star),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );

    final leading = find.byIcon(Icons.star);
    final trailing = find.byIcon(Icons.chevron_right);
    expect(
      tester.getCenter(leading).dx,
      lessThan(tester.getCenter(find.text('继续')).dx),
    );
    expect(
      tester.getCenter(trailing).dx,
      greaterThan(tester.getCenter(find.text('继续')).dx),
    );
    for (final finder in [leading, trailing]) {
      final theme = IconTheme.of(tester.element(finder));
      expect(theme.color, AppColors.light.primaryForeground);
      expect(theme.size, 18);
    }
  });

  for (final useIcon in [false, true]) {
    testWidgets('加载替换${useIcon ? 'icon' : 'leading'}，保留 trailing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          AppButton(
            label: '保存',
            onPressed: () {},
            loading: true,
            icon: useIcon ? Icons.add : null,
            leading: useIcon ? null : const Icon(Icons.star),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  }

  for (final variant in AppButtonVariant.values) {
    for (final size in AppButtonSize.values) {
      testWidgets('${variant.name}/${size.name} 的视觉外沿仍可点击且触控区至少 48px', (
        tester,
      ) async {
        var taps = 0;
        await tester.pumpWidget(
          _buildTestApp(
            AppButton(
              label: '按',
              variant: variant,
              size: size,
              onPressed: () => taps++,
            ),
          ),
        );
        final button = find.byType(TextButton);
        final bounds = tester.getRect(button);
        final visual = tester.getRect(
          find.descendant(of: button, matching: find.byType(Material)),
        );
        expect(bounds.width, greaterThanOrEqualTo(48));
        expect(bounds.height, 48);
        final top = Offset(bounds.center.dx, bounds.top + 1);
        final bottom = Offset(bounds.center.dx, bounds.bottom - 1);
        expect(visual.contains(top), isFalse);
        expect(visual.contains(bottom), isFalse);
        await tester.tapAt(top);
        await tester.tapAt(bottom);
        expect(taps, 2);
      });
    }
  }

  testWidgets('Tab/空格激活按钮并跳过禁用和加载按钮', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      _buildTestApp(
        Column(
          children: [
            AppButton(label: '首个', onPressed: () => taps.add('首个')),
            const AppButton(label: '禁用'),
            AppButton(
              label: '加载',
              loading: true,
              onPressed: () => taps.add('加载'),
            ),
            AppButton(label: '末尾', onPressed: () => taps.add('末尾')),
          ],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.getSemantics(find.text('首个')), isSemantics(isFocused: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, ['首个']);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.getSemantics(find.text('末尾')), isSemantics(isFocused: true));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, ['首个', '末尾']);
    for (final label in ['首个', '禁用', '加载', '末尾']) {
      final enabled = label == '首个' || label == '末尾';
      expect(
        tester.getSemantics(find.text(label)),
        isSemantics(
          label: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: enabled,
          hasTapAction: enabled,
        ),
      );
    }
  });

  testWidgets('窄屏三倍字体及双插槽不溢出，语义保留完整文案', (tester) async {
    const label = '非常长的按钮文案需要完整朗读';
    await tester.pumpWidget(
      _buildTestApp(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3)),
          child: SizedBox(
            width: 160,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final size in AppButtonSize.values)
                  AppButton(
                    label: '$label${size.name}',
                    size: size,
                    expand: true,
                    onPressed: () {},
                    leading: const Icon(Icons.star),
                    trailing: const Icon(Icons.chevron_right),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final size in AppButtonSize.values) {
      final text = find.text('$label${size.name}');
      final button = find.ancestor(of: text, matching: find.byType(TextButton));
      expect(tester.getSize(button).width, 160);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(text),
        isSemantics(label: '$label${size.name}', isButton: true),
      );
    }
  });
}
