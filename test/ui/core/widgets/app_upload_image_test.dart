import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_upload_image.dart';
import 'package:flutter_test/flutter_test.dart';

final _image = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  ),
);

AppUploadImageItem _item(
  Object id, {
  AppUploadImageStatus status = AppUploadImageStatus.success,
  double progress = 0,
}) => AppUploadImageItem(
  id: id,
  image: _image,
  status: status,
  progress: progress,
);

Widget _app(
  Widget child, {
  bool dark = false,
  double width = 360,
  double textScale = 1,
  Locale locale = const Locale('zh'),
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

void main() {
  test('参数约束和列表快照', () {
    expect(() => AppUploadImage(items: [], maxCount: 0), throwsAssertionError);
    expect(
      () => AppUploadImage(items: [_item('a'), _item('a')]),
      throwsAssertionError,
    );
    expect(
      () => AppUploadImage(items: [_item('a'), _item('b')], maxCount: 1),
      throwsAssertionError,
    );
    for (final extent in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => AppUploadImage(items: [], maxItemExtent: extent),
        throwsAssertionError,
      );
    }
    expect(() => _item('a', progress: 1.1), throwsAssertionError);
    final items = [_item('a')];
    final widget = AppUploadImage(items: items);
    items.clear();
    expect(widget.items.single.id, 'a');
    expect(widget.items.clear, throwsUnsupportedError);
  });

  testWidgets('渲染标签、计数与提示文案', (tester) async {
    await tester.pumpWidget(
      _app(
        AppUploadImage(
          label: '上传图片',
          hint: '支持 JPG / PNG，单张不超过 10MB',
          items: [_item('a')],
          onAdd: () {},
        ),
      ),
    );
    expect(find.text('上传图片'), findsOneWidget);
    expect(find.text('1/9'), findsOneWidget);
    expect(find.text('支持 JPG / PNG，单张不超过 10MB'), findsOneWidget);
  });

  testWidgets('添加入口支持点击和无障碍操作', (tester) async {
    var added = 0;
    await tester.pumpWidget(
      _app(AppUploadImage(items: [], onAdd: () => added++)),
    );
    await tester.tap(find.text('添加图片'));
    expect(added, 1);
    final node = tester.getSemantics(find.bySemanticsLabel('添加图片'));
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    tester.binding.performSemanticsAction(
      ui.SemanticsActionEvent(
        type: ui.SemanticsAction.tap,
        nodeId: node.id,
        viewId: tester.view.viewId,
      ),
    );
    expect(added, 2);
  });

  testWidgets('adding 保留占位且禁止重复添加，结束后恢复', (tester) async {
    var added = 0;
    for (final adding in [true, false]) {
      await tester.pumpWidget(
        _app(AppUploadImage(items: [], adding: adding, onAdd: () => added++)),
      );
      final label = adding ? '上传中' : '添加图片';
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(
        node.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        !adding,
      );
      await tester.tap(find.text(adding ? '上传中' : '添加图片'));
      expect(added, adding ? 0 : 1);
    }
  });

  testWidgets('达到上限或只读时隐藏添加入口', (tester) async {
    await tester.pumpWidget(
      _app(AppUploadImage(items: [_item('a')], maxCount: 1, onAdd: () {})),
    );
    expect(find.text('添加图片'), findsNothing);
    await tester.pumpWidget(_app(AppUploadImage(items: [])));
    expect(find.text('添加图片'), findsNothing);
  });

  testWidgets('稳定 ID 在重排后用于预览、重试与删除，保留对应元素', (tester) async {
    final removed = <Object>[];
    final retried = <Object>[];
    final previewed = <Object>[];
    final success = _item('success');
    final failed = _item('failed', status: AppUploadImageStatus.failed);
    Widget build(List<AppUploadImageItem> items) => _app(
      AppUploadImage(
        items: items,
        onRemove: removed.add,
        onRetry: retried.add,
        onPreview: previewed.add,
      ),
    );
    await tester.pumpWidget(build([success, failed]));
    final element = tester.element(
      find.byKey(const ValueKey<Object>('success')),
    );
    await tester.pumpWidget(build([failed, success]));
    expect(
      tester.element(find.byKey(const ValueKey<Object>('success'))),
      same(element),
    );
    await tester.tap(find.bySemanticsLabel('重试上传'));
    await tester.tap(find.byKey(const ValueKey<Object>('success')));
    final delete = find.descendant(
      of: find.byKey(const ValueKey<Object>('failed')),
      matching: find.byType(IconButton),
    );
    await tester.tap(delete);
    expect(retried, ['failed']);
    expect(previewed, ['success']);
    expect(removed, ['failed']);
  });

  testWidgets('只读成功和失败项不宣称可交互', (tester) async {
    await tester.pumpWidget(
      _app(
        AppUploadImage(
          items: [
            _item('a'),
            _item('b', status: AppUploadImageStatus.failed),
          ],
        ),
      ),
    );
    expect(find.text('重试上传'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
    for (final label in ['已上传图片', '上传失败']) {
      final data = tester
          .getSemantics(find.bySemanticsLabel(label))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isFalse);
      expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
    }
  });

  testWidgets('预览和重试的无障碍点击显式触发 ID 回调', (tester) async {
    Object? previewed;
    Object? retried;
    await tester.pumpWidget(
      _app(
        AppUploadImage(
          items: [
            _item('a'),
            _item('b', status: AppUploadImageStatus.failed),
          ],
          onPreview: (id) => previewed = id,
          onRetry: (id) => retried = id,
        ),
      ),
    );
    for (final label in ['预览图片', '重试上传']) {
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      tester.binding.performSemanticsAction(
        ui.SemanticsActionEvent(
          type: ui.SemanticsAction.tap,
          nodeId: node.id,
          viewId: tester.view.viewId,
        ),
      );
    }
    expect(previewed, 'a');
    expect(retried, 'b');
  });

  testWidgets('上传中展示进度且禁用图片交互和删除', (tester) async {
    var actions = 0;
    await tester.pumpWidget(
      _app(
        AppUploadImage(
          items: [
            _item('a', status: AppUploadImageStatus.uploading, progress: 0.65),
          ],
          onRemove: (_) => actions++,
          onPreview: (_) => actions++,
          onRetry: (_) => actions++,
        ),
      ),
    );
    expect(find.text('65%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    final data = tester
        .getSemantics(find.bySemanticsLabel('上传中 65%'))
        .getSemanticsData();
    expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
    await tester.tap(find.bySemanticsLabel('上传中 65%'));
    expect(actions, 0);
  });

  testWidgets('删除按钮 48px 热区完全位于槽位内', (tester) async {
    var removed = 0;
    await tester.pumpWidget(
      _app(AppUploadImage(items: [_item('a')], onRemove: (_) => removed++)),
    );
    final deleteLabel = MaterialLocalizations.of(
      tester.element(find.byType(AppUploadImage)),
    ).deleteButtonTooltip;
    expect(find.bySemanticsLabel(deleteLabel), findsOneWidget);
    expect(find.byTooltip(deleteLabel), findsOneWidget);
    final slot = tester.getRect(find.byKey(const ValueKey<Object>('a')));
    final button = tester.getRect(find.byType(IconButton));
    expect(button.size, const Size(48, 48));
    expect(slot.intersect(button), button);
    await tester.tapAt(button.bottomLeft + const Offset(2, -2));
    expect(removed, 1);
  });

  testWidgets('删除的键盘、语义与边缘点击只调用删除，不穿透至预览', (tester) async {
    final removed = <Object>[];
    final previewed = <Object>[];
    await tester.pumpWidget(
      _app(
        AppUploadImage(
          items: [_item('stable-id')],
          onRemove: removed.add,
          onPreview: previewed.add,
        ),
      ),
    );
    final button = find.byType(IconButton);
    final rect = tester.getRect(button);
    await tester.tapAt(rect.bottomLeft + const Offset(2, -2));
    expect(removed, ['stable-id']);
    final deleteLabel = MaterialLocalizations.of(tester.element(button))
        .deleteButtonTooltip;
    final node = tester.getSemantics(find.bySemanticsLabel(deleteLabel));
    expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
    tester.binding.performSemanticsAction(
      ui.SemanticsActionEvent(
        type: ui.SemanticsAction.tap,
        nodeId: node.id,
        viewId: tester.view.viewId,
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus!.context!
          .findAncestorWidgetOfExactType<IconButton>(),
      same(tester.widget<IconButton>(button)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(removed, List.filled(4, 'stable-id'));
    expect(previewed, isEmpty);
  });

  testWidgets('最大尺寸控制响应式列数，adding 仍参与排列', (tester) async {
    for (final (width, extent, columns) in [
      (360.0, 128.0, 3),
      (720.0, 128.0, 6),
      (360.0, 180.0, 2),
      (100.0, 128.0, 1),
    ]) {
      await tester.pumpWidget(
        _app(
          AppUploadImage(
            items: [for (var i = 0; i < 6; i++) _item(i)],
            maxItemExtent: extent,
            adding: true,
            onAdd: () {},
          ),
          width: width,
        ),
      );
      final first = tester.getRect(find.byKey(const ValueKey<Object>(0)));
      final nextRow = columns == 6
          ? tester.getRect(find.bySemanticsLabel('上传中'))
          : tester.getRect(find.byKey(ValueKey<Object>(columns)));
      expect(first.width, lessThanOrEqualTo(extent));
      expect(first.width, first.height);
      expect(nextRow.top, greaterThan(first.top));
      if (columns > 1) {
        final last = tester.getRect(find.byKey(ValueKey<Object>(columns - 1)));
        expect(last.top, first.top);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Tab 聚焦预览、重试和添加，Enter 与 Space 均回传稳定 ID', (tester) async {
    final actions = <String>[];
    await tester.pumpWidget(
      _app(
        AppUploadImage(
          items: [
            _item('success'),
            _item('failed', status: AppUploadImageStatus.failed),
          ],
          onPreview: (id) => actions.add('preview:$id'),
          onRetry: (id) => actions.add('retry:$id'),
          onAdd: () => actions.add('add'),
        ),
      ),
    );
    final buttons = find.byType(InkWell);
    expect(buttons, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<InkWell>(),
        same(tester.widget<InkWell>(buttons.at(i))),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
    }
    expect(actions, [
      'preview:success',
      'preview:success',
      'retry:failed',
      'retry:failed',
      'add',
      'add',
    ]);
  });

  testWidgets('已聚焦入口变为只读、上传中或 adding 后不响应键盘和点击', (tester) async {
    for (final mode in ['preview', 'retry', 'uploading', 'adding']) {
      var actions = 0;
      Widget build({required bool disabled}) => _app(
        AppUploadImage(
          items: mode == 'adding'
              ? []
              : [
                  _item(
                    'a',
                    status: mode == 'retry'
                        ? AppUploadImageStatus.failed
                        : disabled && mode == 'uploading'
                        ? AppUploadImageStatus.uploading
                        : AppUploadImageStatus.success,
                  ),
                ],
          adding: disabled && mode == 'adding',
          onAdd: mode == 'adding' ? () => actions++ : null,
          onPreview: disabled && mode == 'preview' ? null : (_) => actions++,
          onRetry: disabled && mode == 'retry' ? null : (_) => actions++,
        ),
      );
      await tester.pumpWidget(build(disabled: false));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(actions, 1);
      await tester.pumpWidget(build(disabled: true));
      final ink = find.byType(InkWell);
      expect(tester.widget<InkWell>(ink).onTap, isNull);
      for (final key in [
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.space,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }
      await tester.tap(ink);
      expect(actions, 1, reason: mode);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('添加、预览和重试整槽空白边缘均为真实点击热区', (tester) async {
    final actions = <String>[];
    await tester.pumpWidget(
      _app(
        AppUploadImage(
          items: [
            _item('a'),
            _item('b', status: AppUploadImageStatus.failed),
          ],
          onPreview: (id) => actions.add('preview:$id'),
          onRetry: (id) => actions.add('retry:$id'),
          onAdd: () => actions.add('add'),
        ),
      ),
    );
    for (final label in ['预览图片', '重试上传', '添加图片']) {
      final rect = tester.getRect(find.bySemanticsLabel(label));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, closeTo(rect.width, 0.001));
      await tester.tapAt(rect.topLeft + const Offset(8, 8));
      await tester.tapAt(rect.bottomRight - const Offset(8, 8));
    }
    expect(actions, [
      'preview:a',
      'preview:a',
      'retry:b',
      'retry:b',
      'add',
      'add',
    ]);
  });

  testWidgets('320 宽两倍字号长标签换行且计数、三态和添加不溢出', (tester) async {
    const label = '这是一段很长的上传图片标签，用来验证大字体下仍然完整显示';
    for (final adding in [false, true]) {
      await tester.pumpWidget(
        _app(
          AppUploadImage(
            label: label,
            items: [
              _item('a'),
              _item(
                'b',
                status: AppUploadImageStatus.uploading,
                progress: 0.65,
              ),
              _item('c', status: AppUploadImageStatus.failed),
            ],
            adding: adding,
            onAdd: () {},
            onRetry: (_) {},
          ),
          width: 320,
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      final labelRect = tester.getRect(find.text(label));
      final countRect = tester.getRect(find.text('3/9'));
      expect(labelRect.right, lessThan(countRect.left));
      expect(countRect.right, lessThanOrEqualTo(320));
      expect(labelRect.height, greaterThan(countRect.height));
    }
  });

  testWidgets('英文默认提示、删除 tooltip 和语义随 locale 切换', (tester) async {
    await tester.pumpWidget(
      _app(
        AppUploadImage(
          items: [
            _item('a'),
            _item('b', status: AppUploadImageStatus.failed),
            _item('c', status: AppUploadImageStatus.uploading, progress: 0.3),
          ],
          onAdd: () {},
          onRemove: (_) {},
        ),
        locale: const Locale('en'),
      ),
    );
    for (final label in [
      'Add image',
      'Uploaded image',
      'Upload failed',
      'Uploading 30%',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.text('Add image'), findsOneWidget);
    expect(find.text('Upload failed'), findsOneWidget);
    final deleteLabel = MaterialLocalizations.of(
      tester.element(find.byType(AppUploadImage)),
    ).deleteButtonTooltip;
    expect(deleteLabel, 'Delete');
    expect(find.byTooltip(deleteLabel), findsNWidgets(2));
    expect(find.bySemanticsLabel(deleteLabel), findsNWidgets(2));
    await tester.pumpWidget(
      _app(
        AppUploadImage(
          items: [
            _item('a'),
            _item('b', status: AppUploadImageStatus.failed),
          ],
          adding: true,
          onAdd: () {},
          onPreview: (_) {},
          onRetry: (_) {},
        ),
        locale: const Locale('en'),
      ),
    );
    for (final label in ['Preview image', 'Retry upload', 'Uploading']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.text('Retry upload'), findsOneWidget);
    expect(find.text('Uploading'), findsOneWidget);
  });

  testWidgets('明暗预览独立提供中文本地化', (tester) async {
    for (final preview in [
      appUploadImageLightPreview,
      appUploadImageDarkPreview,
    ]) {
      await tester.pumpWidget(preview());
      expect(find.text('添加图片'), findsOneWidget);
      expect(find.text('重试上传'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('暗色主题正常展示三态', (tester) async {
    await tester.pumpWidget(
      _app(
        AppUploadImage(
          items: [
            _item('a'),
            _item('b', status: AppUploadImageStatus.uploading, progress: 0.3),
            _item('c', status: AppUploadImageStatus.failed),
          ],
          onAdd: () {},
        ),
        dark: true,
      ),
    );
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('上传失败'), findsOneWidget);
    expect(find.text('添加图片'), findsOneWidget);
  });
}
