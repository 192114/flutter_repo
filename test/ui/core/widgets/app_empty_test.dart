import 'dart:math' as math;
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_repo/ui/core/theme/app_colors.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_button.dart';
import 'package:flutter_repo/ui/core/widgets/app_empty.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(
  Widget child, {
  double width = 320,
  double textScale = 1,
  ThemeMode themeMode = ThemeMode.light,
}) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: themeMode,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  testWidgets('标准布局仅必填内容时保留图文尺寸和外边距', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppEmpty(icon: Icon(Icons.inbox_outlined), title: '暂无内容'),
      ),
    );

    expect(find.text('暂无内容'), findsOneWidget);
    final empty = tester.getRect(find.byType(AppEmpty));
    final icon = tester.getRect(find.byIcon(Icons.inbox_outlined));
    final title = tester.getRect(find.text('暂无内容'));
    expect(icon.size, const Size.square(96));
    expect(icon.top - empty.top, 24);
    expect(title.top - icon.bottom, 24);
    expect(empty.bottom - title.bottom, 24);
    expect(icon.center.dx, empty.center.dx);
    expect(title.center.dx, empty.center.dx);
    expect(tester.widget<Text>(find.text('暂无内容')).textAlign, TextAlign.center);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact 仅必填内容时横排图文并使用紧凑尺寸', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        const AppEmpty(
          icon: Icon(Icons.inbox_outlined),
          title: '暂无内容',
          compact: true,
        ),
      ),
    );

    final empty = tester.getRect(find.byType(AppEmpty));
    final icon = tester.getRect(find.byIcon(Icons.inbox_outlined));
    final title = tester.getRect(find.text('暂无内容'));
    expect(icon.size, const Size.square(40));
    expect(icon.left - empty.left, 16);
    expect(icon.top - empty.top, 16);
    expect(empty.bottom - icon.bottom, 16);
    expect(title.left - icon.right, 16);
    expect(title.center.dy, icon.center.dy);
    expect(tester.widget<Text>(find.text('暂无内容')).textAlign, TextAlign.start);
    expect(tester.takeException(), isNull);
  });

  for (final compact in [false, true]) {
    final layout = compact ? 'compact' : '标准';

    for (final description in <String?>[null, '', '请尝试添加内容']) {
      for (final hasAction in [false, true]) {
        testWidgets(
          '$layout description=${description ?? 'null'} action=$hasAction 独立选填且不残留间距',
          (tester) async {
            const actionKey = ValueKey('action');
            await tester.pumpWidget(
              _buildTestApp(
                AppEmpty(
                  icon: const Icon(Icons.inbox_outlined),
                  title: '暂无内容',
                  description: description,
                  action: hasAction
                      ? const SizedBox(key: actionKey, width: 64, height: 20)
                      : null,
                  compact: compact,
                ),
              ),
            );

            final title = tester.getRect(find.text('暂无内容'));
            final hasDescription =
                description != null && description.isNotEmpty;
            var contentHeight = title.height;
            var lastText = title;
            if (hasDescription) {
              expect(find.text(description), findsOneWidget);
              final detail = tester.getRect(find.text(description));
              final gap = compact ? 4.0 : 8.0;
              expect(detail.top - title.bottom, gap);
              contentHeight += gap + detail.height;
              lastText = detail;
            } else {
              expect(find.text(''), findsNothing);
              expect(find.text('请尝试添加内容'), findsNothing);
            }

            if (hasAction) {
              final action = tester.getRect(find.byKey(actionKey));
              final gap = compact ? 16.0 : 24.0;
              expect(action.top - lastText.bottom, gap);
              expect(action.height, 48);
              if (compact) {
                expect(action.left, title.left);
              } else {
                expect(action.center.dx, title.center.dx);
              }
              contentHeight += gap + action.height;
            } else {
              expect(find.byKey(actionKey), findsNothing);
            }

            final expectedHeight = compact
                ? 32 + math.max(40, contentHeight)
                : 48 + 96 + 24 + contentHeight;
            expect(
              tester.getSize(find.byType(AppEmpty)).height,
              closeTo(expectedHeight, 0.001),
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets('$layout 保留调用方传入的非 Icon widget 及其图像语义', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final custom = Semantics(
          key: const ValueKey('custom-illustration'),
          image: true,
          label: '自定义空状态图像',
          child: const ColoredBox(color: Colors.amber),
        );
        await tester.pumpWidget(
          _buildTestApp(
            AppEmpty(icon: custom, title: '自定义插画', compact: compact),
          ),
        );

        final finder = find.byKey(custom.key!);
        expect(tester.widget(finder), same(custom));
        expect(tester.getSize(finder), Size.square(compact ? 40 : 96));
        expect(find.byType(Icon), findsNothing);
        final image = tester.getSemantics(find.bySemanticsLabel('自定义空状态图像'));
        expect(image.flagsCollection.isImage, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('$layout 底部 Wrap 多按钮换行后均可点击', (tester) async {
      var refreshed = 0;
      var created = 0;
      const refreshKey = ValueKey('refresh');
      const createKey = ValueKey('create');
      await tester.pumpWidget(
        _buildTestApp(
          AppEmpty(
            icon: const Icon(Icons.inbox_outlined),
            title: '暂无内容',
            compact: compact,
            action: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  key: refreshKey,
                  width: 64,
                  child: AppButton(label: '刷新', onPressed: () => refreshed++),
                ),
                SizedBox(
                  key: createKey,
                  width: 64,
                  child: AppButton(label: '新建', onPressed: () => created++),
                ),
              ],
            ),
          ),
          width: 160,
        ),
      );

      final refresh = tester.getRect(find.byKey(refreshKey));
      final create = tester.getRect(find.byKey(createKey));
      expect(create.top - refresh.bottom, 8);
      expect(find.text('刷新').hitTestable(), findsOneWidget);
      expect(find.text('新建').hitTestable(), findsOneWidget);
      await tester.tap(find.text('刷新'));
      await tester.tap(find.text('新建'));
      await tester.pumpAndSettle();
      expect(refreshed, 1);
      expect(created, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$layout 标题描述和 IconTheme 随浅暗主题往返切换', (tester) async {
      final child = AppEmpty(
        icon: const Icon(Icons.inbox_outlined),
        title: '暂无内容',
        description: '稍后再来看看',
        compact: compact,
      );
      for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.light]) {
        await tester.pumpWidget(_buildTestApp(child, themeMode: mode));
        await tester.pumpAndSettle();

        final colors = mode == ThemeMode.dark
            ? AppColors.dark
            : AppColors.light;
        final title = tester.widget<Text>(find.text('暂无内容'));
        final description = tester.widget<Text>(find.text('稍后再来看看'));
        final iconTheme = IconTheme.of(
          tester.element(find.byIcon(Icons.inbox_outlined)),
        );
        expect(title.style?.color, colors.foreground);
        expect(title.style?.fontSize, compact ? 16 : 18);
        expect(title.style?.fontWeight, FontWeight.w600);
        expect(description.style?.color, colors.mutedForeground);
        expect(description.style?.fontSize, 14);
        expect(
          description.textAlign,
          compact ? TextAlign.start : TextAlign.center,
        );
        expect(iconTheme.color, colors.mutedForeground);
        expect(iconTheme.size, compact ? 40 : 96);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('$layout 保留图标语义及动作的辅助功能点击', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var tapped = 0;
        await tester.pumpWidget(
          _buildTestApp(
            AppEmpty(
              icon: const Icon(Icons.inbox_outlined, semanticLabel: '空收件箱插图'),
              title: '暂无内容',
              description: '添加第一条内容',
              compact: compact,
              action: TextButton(
                onPressed: () => tapped++,
                child: const Text('创建内容'),
              ),
            ),
          ),
        );

        final icon = tester.getSemantics(find.bySemanticsLabel('空收件箱插图'));
        expect(icon.label, '空收件箱插图');
        expect(find.bySemanticsLabel(RegExp('暂无内容')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('添加第一条内容')), findsOneWidget);
        final action = tester.getSemantics(find.bySemanticsLabel('创建内容'));
        expect(action.flagsCollection.isButton, isTrue);
        expect(action.flagsCollection.isEnabled, Tristate.isTrue);
        expect(
          action.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        action.owner!.performAction(action.id, SemanticsAction.tap);
        await tester.pump();
        expect(tapped, 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });

    for (final width in [160.0, 320.0]) {
      for (final textScale in [2.0, 3.0]) {
        testWidgets('$layout 宽度 $width 字号 ${textScale}x 长文本可滚动且无溢出', (
          tester,
        ) async {
          const title = '暂时没有找到任何相关内容，请尝试其他关键字';
          const description = '这里会展示你创建或收藏的内容。你可以调整筛选条件，或者添加第一条内容后再回来查看。';
          var tapped = 0;
          await tester.pumpWidget(
            _buildTestApp(
              SizedBox(
                height: 180,
                child: SingleChildScrollView(
                  child: AppEmpty(
                    icon: const Icon(Icons.inbox_outlined),
                    title: title,
                    description: description,
                    compact: compact,
                    action: TextButton(
                      onPressed: () => tapped++,
                      child: const Text('重试'),
                    ),
                  ),
                ),
              ),
              width: width,
              textScale: textScale,
            ),
          );

          expect(tester.takeException(), isNull);
          final empty = tester.getRect(find.byType(AppEmpty));
          for (final text in [title, description]) {
            final finder = find.text(text);
            final paragraph = tester.renderObject<RenderParagraph>(finder);
            final rect = tester.getRect(finder);
            expect(paragraph.didExceedMaxLines, isFalse);
            expect(rect.left, greaterThanOrEqualTo(empty.left));
            expect(rect.right, lessThanOrEqualTo(empty.right));
          }
          final scrollable = tester.state<ScrollableState>(
            find.byType(Scrollable),
          );
          expect(scrollable.position.maxScrollExtent, greaterThan(0));
          await tester.ensureVisible(find.text('重试'));
          await tester.pumpAndSettle();
          expect(scrollable.position.pixels, greaterThan(0));
          expect(find.text('重试').hitTestable(), findsOneWidget);
          await tester.tap(find.text('重试'));
          expect(tapped, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
