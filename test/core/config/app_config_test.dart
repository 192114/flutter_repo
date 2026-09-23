import 'package:flutter_repo/core/config/app_config.dart';
import 'package:flutter_repo/data/services/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 环境配置测试：
/// 1. 枚举解析的穷举与回落；
/// 2. 无 dart-define 时的安全缺省与外部输入校验；
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
      expect(EnvConstants.apiConnectTimeoutMs, '10000');
      expect(EnvConstants.apiReceiveTimeoutMs, '10000');
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

      expect(
        container.read(appConfigProvider).environment,
        AppEnvironment.staging,
      );
    });
  });

  group('AppConfig.fromEnvironment 外部输入校验', () {
    test('四个原始参数均使用显式传入值，超时保留毫秒精度', () {
      final config = AppConfig.fromEnvironment(
        environment: 'PRODUCTION',
        baseUrl: 'http://localhost:8080/api/v1',
        connectTimeoutMs: '1',
        receiveTimeoutMs: '15001',
      );

      expect(config.environment, AppEnvironment.prod);
      expect(config.baseUrl, 'http://localhost:8080/api/v1');
      expect(config.connectTimeout, const Duration(milliseconds: 1));
      expect(config.receiveTimeout, const Duration(milliseconds: 15001));
    });

    test('可单独覆盖超时，其余参数保留各自缺省值', () {
      final config = AppConfig.fromEnvironment(receiveTimeoutMs: '1');

      expect(config.environment, AppEnvironment.dev);
      expect(config.baseUrl, 'https://jsonplaceholder.typicode.com');
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.receiveTimeout, const Duration(milliseconds: 1));
    });

    for (final environment in ['', 'unknown', 'prod ']) {
      test('未知环境 "$environment" 仍回落 dev', () {
        expect(
          AppConfig.fromEnvironment(environment: environment).environment,
          AppEnvironment.dev,
        );
      });
    }

    for (final url in [
      'https://api.example.com',
      'HTTP://EXAMPLE.COM/api',
      'http://localhost',
      'http://localhost:1/api',
      'https://localhost:65535/api/v1/',
      'http://127.0.0.1:8080/api',
      'http://[::1]',
      'https://[2001:db8::1]:8443/api',
      'http://[::1]:65535/api',
      'https://example.com:443/api',
      'http://example.com:80/api',
      'https://example.invalid/path:',
      'https://example.com/api%20v1?limit=10#section',
      'http://user:password@localhost/api',
    ]) {
      test('接受合法 URL 并保留原值：$url', () {
        expect(AppConfig.fromEnvironment(baseUrl: url).baseUrl, url);
      });
    }

    const invalidUrls = {
      '空串': '',
      '纯空白': ' \t\n',
      '相对路径': '/api/v1',
      '缺少协议': 'example.com/api',
      '协议相对地址': '//example.com/api',
      '不支持的协议': 'ftp://example.com/api',
      '非层级地址': 'https:example.com',
      '缺少主机': 'https://',
      '仅端口无主机': 'https://:443/api',
      '多余斜杠导致无主机': 'https:///api',
      '前导空白': ' https://example.com',
      '尾随空白': 'https://example.com ',
      '主机含空格': 'https://exam ple.com',
      '路径含空格': 'https://example.com/api v1',
      '查询含换行': 'https://example.com?token=private\nvalue',
      '制表符': 'https://example.com/\tapi',
      'Unicode 空白': 'https://example.com/\u00a0api',
      '反斜杠': 'https://example.com\\api',
      '空端口': 'https://example.com:',
      'IPv6 空端口': 'http://[::1]:/api',
      '非数字端口': 'https://user:private@example.com:invalid?token=secret',
      '小数端口': 'https://example.com:80.5',
      '带正号端口': 'https://example.com:+80',
      '负数端口': 'https://example.com:-1',
      '零端口': 'https://example.com:0',
      '端口超出范围': 'https://example.com:65536',
      'IPv6 端口超出范围': 'http://[::1]:65536/api',
      '端口整数溢出': 'https://example.com:999999999999999999999999',
      '未闭合 IPv6': 'https://[::1/api?token=private',
      '非法 IPv6': 'https://[invalid]/api',
    };
    for (final entry in invalidUrls.entries) {
      test('拒绝${entry.key}且异常不泄露原始 URL', () {
        expect(
          () => AppConfig.fromEnvironment(baseUrl: entry.value),
          _configurationError(
            'API_BASE_URL must be an absolute HTTP(S) URL with a non-empty '
            'host and a port between 1 and 65535 when specified.',
          ),
        );
      });
    }

    const invalidTimeouts = {
      '零': '0',
      '负数': '-1',
      '非整数': '1.5',
      '科学计数法': '1e3',
      '十六进制': '0x10',
      '非数字': 'private-invalid-timeout',
      '空串': '',
      '纯空白': ' \t\n',
      '整数溢出': '999999999999999999999999',
      'Duration 溢出': '9223372036854775807',
    };
    for (final isConnectTimeout in [true, false]) {
      final key = isConnectTimeout
          ? 'API_CONNECT_TIMEOUT_MS'
          : 'API_RECEIVE_TIMEOUT_MS';
      for (final entry in invalidTimeouts.entries) {
        test('$key 拒绝${entry.key}且异常不泄露原始值', () {
          expect(
            () => AppConfig.fromEnvironment(
              connectTimeoutMs: isConnectTimeout ? entry.value : '17',
              receiveTimeoutMs: isConnectTimeout ? '19' : entry.value,
            ),
            _configurationError(
              '$key must be a positive integer in milliseconds.',
            ),
          );
        });
      }
    }

    test('校验仅作用于外部输入工厂，不改变 const AppConfig 注入语义', () {
      const config = AppConfig(
        environment: AppEnvironment.staging,
        baseUrl: 'test-only-value',
        connectTimeout: Duration.zero,
        receiveTimeout: Duration(milliseconds: -1),
      );
      final container = ProviderContainer(
        overrides: [appConfigProvider.overrideWithValue(config)],
      );
      addTearDown(container.dispose);

      expect(container.read(appConfigProvider), same(config));
      expect(config.connectTimeout, Duration.zero);
      expect(config.receiveTimeout, const Duration(milliseconds: -1));
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

Matcher _configurationError(String message) => throwsA(
  isA<FormatException>()
      .having((error) => error.message, 'message', message)
      .having((error) => error.source, 'source', isNull)
      .having((error) => error.offset, 'offset', isNull),
);
