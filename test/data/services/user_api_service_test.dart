// 网络层行为测试：通过桩 HttpClientAdapter 模拟响应，不发真实网络请求。

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_repo/data/exceptions/app_exception.dart';
import 'package:flutter_repo/data/services/user_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 桩适配器：返回预设响应体（HTTP 200），不发真实网络请求。
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // 必须声明 JSON content-type，dio 的 Transformer 才会执行 JSON 解码。
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  UserApiService buildService(String body) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.httpClientAdapter = _StubAdapter(body);
    return UserApiService(dio);
  }

  group('UserApiService', () {
    test('fetchUser 正常解析 JSON 响应', () async {
      final service = buildService('{"id": 1, "name": "Leanne Graham"}');

      final user = await service.fetchUser(1);

      expect(user.id, 1);
      expect(user.name, 'Leanne Graham');
    });

    test('fetchUser 响应体为空时抛 NotFoundException（而非 Null check Error）', () async {
      // JSON null 解码后 response.data 为 null（HTTP 仍为 200）。
      final service = buildService('null');

      await expectLater(
        service.fetchUser(1),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
