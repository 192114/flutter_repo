import 'package:flutter/material.dart';
import 'package:flutter_repo/l10n/app_localizations.dart';
import 'package:flutter_repo/ui/core/theme/app_theme.dart';
import 'package:flutter_repo/ui/core/widgets/async_value_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp(Widget child, {Locale locale = const Locale('zh')}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('英文安全错误与重试文案本地化并保留自定义错误消息', (tester) async {
    var retried = 0;
    final value = AsyncValue<String>.error(
      StateError('secret-token'),
      StackTrace.empty,
    );
    await tester.pumpWidget(
      _buildTestApp(
        AsyncValueView<String>(
          value: value,
          onRetry: () => retried++,
          data: Text.new,
        ),
        locale: const Locale('en'),
      ),
    );
    expect(
      find.text('Unable to load. Please try again later.'),
      findsOneWidget,
    );
    expect(find.textContaining('secret-token'), findsNothing);
    expect(find.text('加载失败，请稍后重试'), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);

    await tester.pumpWidget(
      _buildTestApp(
        AsyncValueView<String>(
          value: value,
          errorMessageBuilder: (_) => '自定义安全消息',
          data: Text.new,
        ),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('自定义安全消息'), findsOneWidget);
    expect(find.textContaining('secret-token'), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('默认错误文案不展示异常详情并支持重试', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      _buildTestApp(
        AsyncValueView<String>(
          value: AsyncValue.error(StateError('secret-token'), StackTrace.empty),
          onRetry: () => retried++,
          data: Text.new,
        ),
      ),
    );
    expect(find.text('加载失败，请稍后重试'), findsOneWidget);
    expect(find.textContaining('secret-token'), findsNothing);
    await tester.tap(find.text('重试'));
    expect(retried, 1);
  });

  testWidgets('errorMessageBuilder 映射安全文案，无回调时隐藏重试', (tester) async {
    final error = StateError('private');
    Object? received;
    await tester.pumpWidget(
      _buildTestApp(
        AsyncValueView<String>(
          value: AsyncValue.error(error, StackTrace.empty),
          errorMessageBuilder: (value) {
            received = value;
            return '连接暂不可用';
          },
          data: Text.new,
        ),
      ),
    );
    expect(received, same(error));
    expect(find.text('连接暂不可用'), findsOneWidget);
    expect(find.text('重试'), findsNothing);
    expect(find.textContaining('private'), findsNothing);
  });

  testWidgets('loadingBuilder 替换默认加载组件', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        AsyncValueView<String>(
          value: const AsyncValue.loading(),
          loadingBuilder: (context) => const Text('自定义加载'),
          data: Text.new,
        ),
      ),
    );
    expect(find.text('自定义加载'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('errorBuilder 收到异常与堆栈且优先于文案 builder', (tester) async {
    final error = StateError('private');
    final stackTrace = StackTrace.current;
    var messageCalls = 0;
    await tester.pumpWidget(
      _buildTestApp(
        AsyncValueView<String>(
          value: AsyncValue.error(error, stackTrace),
          errorMessageBuilder: (_) {
            messageCalls++;
            return '不应展示';
          },
          errorBuilder: (context, value, stack) {
            expect(value, same(error));
            expect(stack, same(stackTrace));
            return const Text('自定义错误');
          },
          data: Text.new,
        ),
      ),
    );
    expect(find.text('自定义错误'), findsOneWidget);
    expect(find.text('不应展示'), findsNothing);
    expect(messageCalls, 0);
  });

  testWidgets('默认 loading 与 data 分别渲染', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        AsyncValueView<String>(
          value: const AsyncValue.loading(),
          data: Text.new,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(
      _buildTestApp(
        AsyncValueView<String>(
          value: const AsyncValue.data('完成'),
          loadingBuilder: (_) => const Text('加载'),
          errorBuilder: (_, _, _) => const Text('错误'),
          data: Text.new,
        ),
      ),
    );
    expect(find.text('完成'), findsOneWidget);
    expect(find.text('加载'), findsNothing);
    expect(find.text('错误'), findsNothing);
  });
}
