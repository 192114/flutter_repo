import 'package:flutter_repo/core/config/app_config.dart';
import 'package:flutter_repo/data/services/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 环境配置测试：
/// 1. 枚举解析的穷举与回落；
/// 2. 无 dart-define 时的安全缺省；
/// 3. dioProvider 与 appConfigProvider 的注入集成。
void main() {
  group('AppEnvironment.parse', () {
    test('正确解析三个环境（含大小写不敏感）', () {
      expect(AppEnvironment.parse('dev'), AppEnvironment.dev);
      expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
      expect(AppEnvironment.parse('prod'), AppEnvironment.prod);
      expect(AppEnvironment.parse('production'), AppEnvironment.prod);
      expect(AppEnvironment.parse('PROD'), AppEnvironment.prod);
    });

    test('非法 / 未知值一律回落 dev（宁可连错环境也不崩溃）', () {
      expect(AppEnvironment.parse(''), AppEnvironment.dev);
      expect(AppEnvironment.parse('unknown'), AppEnvironment.dev);
      expect(AppEnvironment.parse('prod '), AppEnvironment.dev);
    });
  });

  group('AppConfig.fromEnvironment（无 dart-define 注入时）', () {
    // flutter test 默认不带 --dart-define，fromEnvironment 读到的
    // 全部是编译期 defaultValue —— 本组测试即验证「安全缺省」行为。
    test('回落 dev + 公共演示 API + 10s 超时', () {
      final config = AppConfig.fromEnvironment();

      expect(config.environment, AppEnvironment.dev);
      expect(config.baseUrl, 'https://jsonplaceholder.typicode.com');
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.receiveTimeout, const Duration(seconds: 10));
    });

    test('缺省配置可被 Provider 覆盖整体替换（DI 可测试性）', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.staging,
              baseUrl: 'https://staging.example.com',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(appConfigProvider).environment,
          AppEnvironment.staging);
    });
  });

  group('dioProvider ← appConfigProvider 集成', () {
    test('Dio 的 baseUrl / 超时完全来自注入的 AppConfig', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.prod,
              baseUrl: 'https://api.example.com',
              connectTimeout: Duration(seconds: 15),
              receiveTimeout: Duration(seconds: 20),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);

      expect(dio.options.baseUrl, 'https://api.example.com');
      expect(dio.options.connectTimeout, const Duration(seconds: 15));
      expect(dio.options.receiveTimeout, const Duration(seconds: 20));
    });

    test('无 override 时使用缺省配置（dev + jsonplaceholder）', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);

      expect(dio.options.baseUrl, 'https://jsonplaceholder.typicode.com');
    });
  });
}
