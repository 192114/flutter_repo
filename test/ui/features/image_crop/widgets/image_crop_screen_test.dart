import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_repo/data/services/image_crop_session_store.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/app_image_cropper.dart';
import 'package:flutter_repo/ui/features/image_crop/widgets/image_crop_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

GoRouter _router({String initialLocation = '/gallery/upload'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/landing',
      builder: (context, state) => const Scaffold(body: Text('入口页')),
    ),
    GoRoute(
      path: '/gallery/upload',
      builder: (context, state) => const Scaffold(body: Text('上传演示')),
    ),
    GoRoute(
      path: '/image-crop/:id',
      builder: (context, state) =>
          ImageCropScreen(sessionId: state.pathParameters['id']!),
    ),
  ],
);

Future<void> _mount(
  WidgetTester tester,
  ProviderContainer container,
  GoRouter router,
) => tester.pumpWidget(
  UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      routerConfig: router,
    ),
  ),
);

Future<void> _decode(WidgetTester tester) async {
  for (var i = 0; i < 200; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (find.byType(AppImageCropper).evaluate().isNotEmpty &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('裁剪页未完成加载');
}

void main() {
  testWidgets('未知会话深链展示明确提示，无返回栈时关闭至上传页', (tester) async {
    final container = ProviderContainer.test();
    final router = _router(initialLocation: '/image-crop/expired');
    addTearDown(router.dispose);
    await _mount(tester, container, router);
    await tester.pumpAndSettle();
    expect(find.text('裁剪会话已过期，请重新选择图片'), findsOneWidget);
    expect(find.byType(AppImageCropper), findsNothing);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('上传演示'), findsOneWidget);
  });

  testWidgets('只通过 ID 打开会话，取消返回 null 并释放源图', (tester) async {
    final container = ProviderContainer.test();
    final sessions = container.read(imageCropSessionStoreProvider);
    final id = sessions.create(_png);
    final router = _router();
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await _mount(tester, container, router);
      final result = router.push<Uint8List>('/image-crop/$id');
      await _decode(tester);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ImageCropScreen>(find.byType(ImageCropScreen)).sessionId,
        id,
      );
      await tester.tap(find.text('取消'));
      expect(await result, isNull);
      expect(sessions.read(id), isNull);
      await tester.pumpAndSettle();
      expect(find.text('上传演示'), findsOneWidget);
    });
  });

  testWidgets('完成通过 go_router 返回 PNG 并释放会话，再访问提示过期', (tester) async {
    final container = ProviderContainer.test();
    final sessions = container.read(imageCropSessionStoreProvider);
    final id = sessions.create(_png);
    final router = _router();
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await _mount(tester, container, router);
      final result = router.push<Uint8List>('/image-crop/$id');
      await _decode(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('完成'));
      final bytes = await result.timeout(const Duration(seconds: 5));
      expect(bytes!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(sessions.read(id), isNull);
      await tester.pumpAndSettle();
      await container.pump();
      unawaited(router.push<void>('/image-crop/$id'));
      await tester.pumpAndSettle();
      expect(find.text('裁剪会话已过期，请重新选择图片'), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('系统返回不触发完成并自动释放会话', (tester) async {
    final container = ProviderContainer.test();
    final sessions = container.read(imageCropSessionStoreProvider);
    final id = sessions.create(_png);
    final router = _router();
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await _mount(tester, container, router);
      final result = router.push<Uint8List>('/image-crop/$id');
      await _decode(tester);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      expect(await result, isNull);
      await tester.pumpAndSettle();
      await container.pump();
      expect(sessions.read(id), isNull);
    });
  });

  testWidgets('返回动画中的迟到完成或取消回调不会再次弹出上传页', (tester) async {
    final container = ProviderContainer.test();
    final sessions = container.read(imageCropSessionStoreProvider);
    final id = sessions.create(_png);
    final router = _router(initialLocation: '/landing');
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await _mount(tester, container, router);
      var uploadPopped = false;
      unawaited(
        router.push<void>('/gallery/upload').then((_) => uploadPopped = true),
      );
      await tester.pumpAndSettle();
      final result = router.push<Uint8List>('/image-crop/$id');
      await _decode(tester);
      await tester.pumpAndSettle();
      final cropper = tester.widget<AppImageCropper>(
        find.byType(AppImageCropper),
      );
      router.pop();
      cropper.onCropped(_png);
      cropper.onCancel();
      expect(await result, isNull);
      expect(sessions.read(id), isNull);
      await tester.pumpAndSettle();
      expect(uploadPopped, isFalse);
      expect(find.text('上传演示'), findsOneWidget);
      expect(router.canPop(), isTrue);
    });
  });

  testWidgets('页面被替换或整个组件树卸载后释放会话', (tester) async {
    for (final unmount in [false, true]) {
      final container = ProviderContainer.test();
      final sessions = container.read(imageCropSessionStoreProvider);
      final id = sessions.create(_png);
      final router = _router(initialLocation: '/image-crop/$id');
      addTearDown(router.dispose);
      await tester.runAsync(() async {
        await _mount(tester, container, router);
        await _decode(tester);
        if (unmount) {
          await tester.pumpWidget(const SizedBox.shrink());
        } else {
          router.go('/gallery/upload');
        }
        await tester.pumpAndSettle();
        await container.pump();
        expect(sessions.read(id), isNull);
      });
    }
  });
}
