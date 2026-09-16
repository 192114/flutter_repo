// 日志管线测试：验证 DioLoggingInterceptor → AppLogger → LogOutput 全链路。
// 通过注入 RecordingOutput 捕获日志，无需真实网络与控制台。

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_repo/core/logging/app_logger.dart';
import 'package:flutter_repo/core/logging/dio_logging_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

/// 记录型 LogOutput：把所有日志行捕获到内存供断言。
class _RecordingOutput extends LogOutput {
  final List<String> lines = [];

  @override
  void output(OutputEvent event) {
    lines.addAll(event.lines);
  }
}

/// 全量放行过滤器（测试环境不依赖 asserts 开关）。
class _AlwaysLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

/// 桩适配器：返回预设状态码与响应体，不发真实网络请求。
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode, this.body);

  final int statusCode;
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
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _RecordingOutput output;

  setUp(() {
    output = _RecordingOutput();
  });

  Dio buildDio(HttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      DioLoggingInterceptor(
        // 依赖注入：测试注入带捕获输出的 AppLogger（SimplePrinter
        // 关闭颜色后输出形如 "[D] message"，可断言级别路由）。
        AppLogger(
          logger: Logger(
            filter: _AlwaysLogFilter(),
            printer: SimplePrinter(colors: false),
            output: output,
          ),
        ),
      ),
    );
    return dio;
  }

  test('成功请求：请求与响应各记录一条 debug 级日志', () async {
    final dio = buildDio(_StubAdapter(200, '[]'));
    await dio.get<List<dynamic>>('/users');

    final all = output.lines.join('\n');
    // 级别路由：请求与响应均为 debug 级，不应出现 error 级。
    expect(all, contains('[D]'));
    expect(all.contains('[E]'), isFalse);
    // 请求日志。
    expect(all, contains('HTTP → GET https://example.com/users'));
    // 响应日志（含状态码）。
    expect(all, contains('HTTP ← GET https://example.com/users 200'));
  });

  test('服务端 500：记录 error 级日志并携带 DioException', () async {
    final dio = buildDio(_StubAdapter(500, 'boom'));

    await expectLater(
      dio.get<List<dynamic>>('/users'),
      throwsA(isA<DioException>()),
    );

    final all = output.lines.join('\n');
    // 级别路由：异常为 error 级。
    expect(all, contains('[E]'));
    expect(all, contains('HTTP ✕ GET https://example.com/users'));
    // error 对象被完整携带（SimplePrinter 以 "ERROR: <error>" 输出）。
    expect(all, contains('ERROR: DioException'));
  });
}
