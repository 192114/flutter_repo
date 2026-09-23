// Repository 异常映射回归：网络 / 解析边界异常必须收敛为 AppException。

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_repo/core/logging/app_logger.dart';
import 'package:flutter_repo/data/exceptions/app_exception.dart';
import 'package:flutter_repo/data/repositories/user_repository_impl.dart';
import 'package:flutter_repo/data/services/user_api_service.dart';
import 'package:flutter_repo/data/services/user_local_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 桩适配器：返回预设响应（状态码 + 响应体），或直接抛出预设异常。
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({this.statusCode = 200, this.body = '{}', this.error});

  final int statusCode;
  final String body;
  final Object? error;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (error != null) {
      throw error!;
    }
    // 必须声明 JSON content-type，dio 的 Transformer 才会执行 JSON 解码。
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 静默日志：测试不向控制台输出。
class _SilentFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  UserRepositoryImpl buildRepository(
    int statusCode,
    String body, {
    Object? error,
  }) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.httpClientAdapter = _StubAdapter(
      statusCode: statusCode,
      body: body,
      error: error,
    );
    return UserRepositoryImpl(
      apiService: UserApiService(dio),
      localService: UserLocalService(prefs),
      logger: AppLogger(logger: Logger(filter: _SilentFilter())),
    );
  }

  group('getUsers 异常映射', () {
    test('列表含非对象项（解析 TypeError）→ UnknownException', () async {
      final repository = buildRepository(
        200,
        '[{"id": 1, "name": "Leanne Graham"}, "oops"]',
      );

      await expectLater(
        repository.getUsers(),
        throwsA(isA<UnknownException>()),
      );
    });

    test('连接失败 → NetworkException', () async {
      final repository = buildRepository(
        200,
        '{}',
        error: DioException.connectionError(
          requestOptions: RequestOptions(path: '/users'),
          reason: 'stub connection failure',
        ),
      );

      await expectLater(
        repository.getUsers(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getUser 异常映射', () {
    test('404 → NotFoundException', () async {
      final repository = buildRepository(404, '{}');

      await expectLater(
        repository.getUser(1),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('500 → UnknownException（当前契约：服务端故障非网络问题）', () async {
      final repository = buildRepository(500, '{}');

      await expectLater(
        repository.getUser(1),
        throwsA(isA<UnknownException>()),
      );
    });

    test('响应体缺必填字段（解析 TypeError）→ UnknownException', () async {
      final repository = buildRepository(200, '{}');

      await expectLater(
        repository.getUser(1),
        throwsA(isA<UnknownException>()),
      );
    });

    test('响应体为 null → NotFoundException 透传（不被覆盖为 Unknown）', () async {
      final repository = buildRepository(200, 'null');

      await expectLater(
        repository.getUser(1),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
