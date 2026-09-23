import 'package:flutter_repo/app.dart';
import 'package:flutter_repo/core/config/app_config.dart';
import 'package:flutter_repo/data/services/shared_preferences_provider.dart';
import 'package:flutter_repo/main.dart';
import 'package:flutter_repo/ui/core/widgets/app_button.dart';
import 'package:flutter_repo/ui/core/widgets/startup_failure_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  const config = AppConfig(
    environment: AppEnvironment.staging,
    baseUrl: 'https://staging.example.com',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  testWidgets('初始化成功后注入已加载的配置和本地存储', (tester) async {
    tester.platformDispatcher.defaultRouteNameTestValue = '/gallery';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    var configLoads = 0;
    var preferencesLoads = 0;

    await bootstrap(
      loadConfig: () {
        configLoads++;
        return config;
      },
      loadPreferences: () async {
        preferencesLoads++;
        return preferences;
      },
    );
    await tester.pumpAndSettle();

    expect(find.byType(App), findsOneWidget);
    expect(find.text('组件库'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(App)),
    );
    expect(container.read(appConfigProvider), same(config));
    expect(container.read(sharedPreferencesProvider), same(preferences));
    expect(configLoads, 1);
    expect(preferencesLoads, 1);
  });

  testWidgets('本地存储初始化失败时显示兜底页且不暴露异常详情', (tester) async {
    await bootstrap(
      loadConfig: () => config,
      loadPreferences: () async => throw StateError('private storage details'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StartupFailureApp), findsOneWidget);
    expect(find.text('启动失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(find.textContaining('private storage details'), findsNothing);
    expect(find.byType(App), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('配置解析失败时显示兜底页且不初始化本地存储', (tester) async {
    var preferencesLoads = 0;
    await bootstrap(
      loadConfig: () => throw const FormatException('API_BASE_URL invalid'),
      loadPreferences: () async {
        preferencesLoads++;
        return preferences;
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('启动失败'), findsOneWidget);
    expect(find.textContaining('API_BASE_URL'), findsNothing);
    expect(preferencesLoads, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('重试再次失败后仍可重试，恢复后进入应用', (tester) async {
    tester.platformDispatcher.defaultRouteNameTestValue = '/gallery';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    var attempts = 0;
    await bootstrap(
      loadConfig: () => config,
      loadPreferences: () async {
        attempts++;
        if (attempts < 3) throw StateError('storage unavailable');
        return preferences;
      },
    );
    await tester.pumpAndSettle();

    expect(attempts, 1);
    // runApp 的根节点重挂载需推进真实事件循环。
    await tester.runAsync(() => tester.tap(find.text('重试')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('启动失败'), findsOneWidget);
    expect(tester.widget<AppButton>(find.byType(AppButton)).loading, isFalse);

    await tester.runAsync(() => tester.tap(find.text('重试')));
    await tester.pumpAndSettle();
    expect(attempts, 3);
    expect(find.byType(App), findsOneWidget);
    expect(find.text('组件库'), findsOneWidget);
    expect(find.byType(StartupFailureApp), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
