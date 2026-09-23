import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_repo/ui/core/widgets/app_button.dart';
import 'package:flutter_repo/ui/core/widgets/startup_failure_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('重试期间显示加载态并阻止重复点击，结束后可再次重试', (tester) async {
    var attempts = 0;
    final pending = Completer<void>();
    await tester.pumpWidget(
      StartupFailureApp(
        onRetry: () {
          attempts++;
          return pending.future;
        },
      ),
    );

    await tester.tap(find.text('重试'));
    await tester.tap(find.text('重试'));
    expect(attempts, 1);
    await tester.pump();
    expect(find.text('正在重试'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<AppButton>(find.byType(AppButton)).loading, isTrue);

    await tester.tap(find.text('正在重试'));
    expect(attempts, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('重试'), findsOneWidget);
    expect(tester.widget<AppButton>(find.byType(AppButton)).loading, isFalse);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('重试未完成时页面销毁不会触发 setState 异常', (tester) async {
    final pending = Completer<void>();
    await tester.pumpWidget(StartupFailureApp(onRetry: () => pending.future));
    await tester.tap(find.text('重试'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('无存储依赖时跟随系统 ${brightness.name} 主题', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(StartupFailureApp(onRetry: () async {}));
      expect(
        Theme.of(tester.element(find.text('启动失败'))).brightness,
        brightness,
      );
      expect(find.text('暂时无法启动应用，请重试。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('窄屏大字号可滚动到重试按钮且无溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    var attempts = 0;
    await tester.pumpWidget(StartupFailureApp(onRetry: () async => attempts++));
    await tester.ensureVisible(find.byType(AppButton));
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(tester.takeException(), isNull);
  });
}
