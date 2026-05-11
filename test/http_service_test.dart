/*
 * HTTP 请求服务测试 — 校验调试日志脱敏边界
 * @Project : SSPU-all-in-one
 * @File : http_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-05-11
 */

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_all_in_one/services/http_service.dart';

void main() {
  test('Debug HTTP 日志不输出查询参数、fragment 或 userInfo', () async {
    final capturedLogs = <String>[];
    final service = HttpService.instance;
    service.dio.httpClientAdapter = _HttpServiceTestAdapter();

    await runZoned(
      () async {
        await service.get<String>(
          'https://user:secret@example.edu.cn/login/path',
          queryParameters: {'token': 'sensitive-token', 'ticket': 'TGT-1'},
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          capturedLogs.add(line);
        },
      ),
    );

    expect(
      capturedLogs,
      contains('[HTTP] → GET https://example.edu.cn/login/path'),
    );
    expect(
      capturedLogs,
      contains('[HTTP] ← 200 https://example.edu.cn/login/path'),
    );
    expect(capturedLogs.join('\n'), isNot(contains('sensitive-token')));
    expect(capturedLogs.join('\n'), isNot(contains('ticket')));
    expect(capturedLogs.join('\n'), isNot(contains('user:secret')));
  });
}

class _HttpServiceTestAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      'ok',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.textPlainContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
