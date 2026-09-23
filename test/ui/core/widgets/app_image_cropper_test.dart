import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_image_cropper.dart';
import 'package:flutter_test/flutter_test.dart';

final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

Future<Uint8List> _makePng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = Colors.red,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<Size> _pngSize(Uint8List bytes) async {
  expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final size = Size(
    frame.image.width.toDouble(),
    frame.image.height.toDouble(),
  );
  frame.image.dispose();
  codec.dispose();
  return size;
}

Widget _app(AppImageCropper child, {Locale locale = const Locale('zh')}) =>
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: child,
    );

Finder _handles(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

Future<void> _decode(WidgetTester tester) async {
  for (var i = 0; i < 200; i++) {
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('图片解码未完成');
}

void main() {
  test('拒绝非法比例、列表和解码尺寸', () {
    AppImageCropper create({
      double? ratio = 1,
      bool locked = false,
      List<double?> allowed = const [null, 1, 4 / 3, 16 / 9],
      int max = 2048,
    }) => AppImageCropper(
      imageBytes: _pngBytes,
      onCropped: (_) {},
      onCancel: () {},
      initialAspectRatio: ratio,
      lockAspectRatio: locked,
      allowedAspectRatios: allowed,
      maxDecodeDimension: max,
    );
    for (final ratio in [0.0, -1.0, double.nan, double.infinity]) {
      expect(() => create(ratio: ratio), throwsAssertionError);
      expect(() => create(allowed: [1, ratio]), throwsAssertionError);
    }
    expect(() => create(locked: true, ratio: null), throwsAssertionError);
    expect(() => create(allowed: []), throwsAssertionError);
    expect(() => create(allowed: [1, 1]), throwsAssertionError);
    expect(() => create(allowed: [null, 1, null]), throwsAssertionError);
    expect(() => create(ratio: 2), throwsAssertionError);
    expect(() => create(max: 0), throwsAssertionError);
    expect(() => create(max: -1), throwsAssertionError);
    final ratios = <double?>[1, 2];
    final cropper = create(allowed: ratios);
    ratios.clear();
    expect(cropper.allowedAspectRatios, [1, 2]);
    expect(cropper.allowedAspectRatios.clear, throwsUnsupportedError);
    expect(create(locked: true, ratio: 2).initialAspectRatio, 2);
  });

  testWidgets('独立组件展示默认比例选项，取消只触发回调', (tester) async {
    var cancelled = 0;
    var cropped = 0;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: _pngBytes,
            onCropped: (_) => cropped++,
            onCancel: () => cancelled++,
          ),
        ),
      );
      await _decode(tester);
      for (final label in ['裁剪图片', '取消', '完成', '自由', '1:1', '4:3', '16:9']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('取消'));
      expect(cancelled, 1);
      expect(cropped, 0);
      expect(find.byType(AppImageCropper), findsOneWidget);
    });
  });

  testWidgets('切换比例与旋转后仍可用，自由模式展示手柄', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: _pngBytes,
            onCropped: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await _decode(tester);
      expect(_handles('裁剪图片'), findsNothing);
      await tester.tap(find.text('16:9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('自由'));
      await tester.pumpAndSettle();
      expect(_handles('裁剪图片'), findsNWidgets(4));
      await tester.tap(find.byTooltip('旋转图片'));
      await tester.pumpAndSettle();
      expect(find.text('裁剪图片'), findsOneWidget);
    });
  });

  testWidgets('锁定自定义比例隐藏选择和手柄，旋转后仍输出相同比例 PNG', (tester) async {
    await tester.runAsync(() async {
      final result = Completer<Uint8List>();
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: await _makePng(120, 80),
            initialAspectRatio: 2,
            lockAspectRatio: true,
            onCropped: result.complete,
            onCancel: () {},
          ),
        ),
      );
      await _decode(tester);
      for (final label in ['自由', '1:1', '4:3', '16:9', '2:1']) {
        expect(find.text(label), findsNothing);
      }
      expect(_handles('裁剪图片'), findsNothing);
      await tester.tap(find.byTooltip('旋转图片'));
      await tester.pump();
      await tester.tap(find.text('完成'));
      final bytes = await result.future.timeout(const Duration(seconds: 5));
      expect(await _pngSize(bytes), const Size(80, 40));
      await tester.pump();
    });
  });

  testWidgets('仅展示允许比例，窄屏长列表不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(240, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: _pngBytes,
            initialAspectRatio: 2,
            allowedAspectRatios: const [2, 3, 4, 5, 6],
            onCropped: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await _decode(tester);
    });
    expect(find.text('自由'), findsNothing);
    expect(find.text('1:1'), findsNothing);
    expect(find.text('2:1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('自由比例旋转 90 度后 PNG 宽高互换且不放大小图', (tester) async {
    await tester.runAsync(() async {
      final result = Completer<Uint8List>();
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: await _makePng(2, 1),
            initialAspectRatio: null,
            onCropped: result.complete,
            onCancel: () {},
          ),
        ),
      );
      await _decode(tester);
      await tester.tap(find.byTooltip('旋转图片'));
      await tester.pump();
      await tester.tap(find.text('完成'));
      expect(await _pngSize(await result.future), const Size(1, 2));
      await tester.pump();
    });
  });

  for (final (width, height, expected) in [
    (120, 60, const Size(40, 20)),
    (60, 120, const Size(20, 40)),
    (120, 1, const Size(40, 1)),
    (1, 120, const Size(1, 40)),
  ]) {
    testWidgets('maxDecodeDimension 限制 ${width}x$height PNG 最长边', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final result = Completer<Uint8List>();
        await tester.pumpWidget(
          _app(
            AppImageCropper(
              imageBytes: await _makePng(width, height),
              initialAspectRatio: null,
              maxDecodeDimension: 40,
              onCropped: result.complete,
              onCancel: () {},
            ),
          ),
        );
        await _decode(tester);
        expect(find.text('图片加载失败'), findsNothing);
        await tester.tap(find.text('完成'));
        final bytes = await result.future.timeout(const Duration(seconds: 5));
        expect(await _pngSize(bytes), expected);
        await tester.pump();
      });
    });
  }

  testWidgets('解码失败可以重试或取消，不触发裁剪完成', (tester) async {
    var cancelled = 0;
    var cropped = 0;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: Uint8List.fromList([1, 2, 3, 4]),
            onCropped: (_) => cropped++,
            onCancel: () => cancelled++,
          ),
        ),
      );
      await _decode(tester);
      expect(find.text('图片加载失败'), findsOneWidget);
      await tester.tap(find.text('完成'));
      expect(cropped, 0);
      await tester.tap(find.text('重试'));
      await _decode(tester);
      expect(find.text('图片加载失败'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '取消'));
      expect(cancelled, 1);
    });
  });

  testWidgets('自由比例拖动手柄越界不崩溃且可导出', (tester) async {
    await tester.runAsync(() async {
      final result = Completer<Uint8List>();
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: _pngBytes,
            initialAspectRatio: null,
            onCropped: result.complete,
            onCancel: () {},
          ),
        ),
      );
      await _decode(tester);
      await tester.drag(_handles('裁剪图片').first, const Offset(-500, -500));
      await tester.pump();
      await tester.tap(find.text('完成'));
      expect(await _pngSize(await result.future), const Size(1, 1));
      await tester.pump();
    });
  });

  testWidgets('替换源图及比例后丢弃旧解码，重置为新的编辑参数', (tester) async {
    await tester.runAsync(() async {
      final result = Completer<Uint8List>();
      final source = await _makePng(120, 60);
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: _pngBytes,
            onCropped: (_) => fail('旧图不应输出'),
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: source,
            initialAspectRatio: null,
            maxDecodeDimension: 60,
            onCropped: result.complete,
            onCancel: () {},
          ),
        ),
      );
      await _decode(tester);
      await tester.tap(find.text('完成'));
      expect(await _pngSize(await result.future), const Size(60, 30));
      await tester.pump();
    });
  });

  testWidgets('英文导航、比例、旋转和手柄语义保留裁剪行为', (tester) async {
    await tester.runAsync(() async {
      final result = Completer<Uint8List>();
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: _pngBytes,
            onCropped: result.complete,
            onCancel: () {},
          ),
          locale: const Locale('en'),
        ),
      );
      await _decode(tester);
      for (final label in ['Crop image', 'Cancel', 'Done', 'Free']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Free'));
      await tester.pumpAndSettle();
      expect(_handles('Crop image'), findsNWidgets(4));
      await tester.tap(find.byTooltip('Rotate image'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      expect(await _pngSize(await result.future), const Size(1, 1));
      await tester.pump();
    });
  });

  testWidgets('英文加载失败提示支持重试和取消，完成保持禁用', (tester) async {
    var cancelled = 0;
    var cropped = 0;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: Uint8List.fromList([1, 2, 3]),
            onCropped: (_) => cropped++,
            onCancel: () => cancelled++,
          ),
          locale: const Locale('en'),
        ),
      );
      await _decode(tester);
      expect(find.text('Unable to load image'), findsOneWidget);
      await tester.tap(find.text('Done'));
      expect(cropped, 0);
      await tester.tap(find.text('Retry'));
      await _decode(tester);
      expect(find.text('Unable to load image'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      expect(cancelled, 1);
    });
  });

  testWidgets('裁剪输出失败使用当前语言提示并允许再次完成', (tester) async {
    for (final (locale, done, failure) in [
      (const Locale('zh'), '完成', '裁剪失败，请重试'),
      (const Locale('en'), 'Done', 'Unable to crop. Please try again.'),
    ]) {
      await tester.runAsync(() async {
        var attempts = 0;
        final attempted = Completer<void>();
        await tester.pumpWidget(
          _app(
            AppImageCropper(
              imageBytes: _pngBytes,
              onCropped: (_) {
                attempts++;
                if (!attempted.isCompleted) attempted.complete();
                throw StateError('Simulated output failure');
              },
              onCancel: () {},
            ),
            locale: locale,
          ),
        );
        await _decode(tester);
        await tester.tap(find.text(done));
        await attempted.future.timeout(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.text(failure), findsOneWidget);
        expect(attempts, 1);
        final action = find.ancestor(
          of: find.text(done),
          matching: find.byType(InkWell),
        );
        expect(tester.widget<InkWell>(action).onTap, isNotNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });

  testWidgets('解码中卸载不更新已销毁组件', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        _app(
          AppImageCropper(
            imageBytes: _pngBytes,
            onCropped: (_) => fail('卸载后不应回调'),
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
