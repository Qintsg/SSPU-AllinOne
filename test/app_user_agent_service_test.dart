/*
 * 应用 User-Agent 服务测试 — 校验 OA/CAS 请求身份标识格式和接入范围
 * @Project : SSPU-AllinOne
 * @File : app_user_agent_service_test.dart
 * @Author : Qintsg
 * @Date : 2026-06-12
 */

import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/services/academic_eams_service.dart';
import 'package:sspu_allinone/services/academic_login_validation_service.dart';
import 'package:sspu_allinone/services/app_info_service.dart';
import 'package:sspu_allinone/services/app_user_agent_service.dart';
import 'package:sspu_allinone/services/campus_card_service.dart';
import 'package:sspu_allinone/services/http_service.dart';
import 'package:sspu_allinone/services/sports_attendance_service.dart';
import 'package:sspu_allinone/services/student_report_service.dart';
import 'package:sspu_allinone/services/wxmp_config_service.dart';

void main() {
  const expectedUserAgent = 'SSPU-AllinOne/1.2.3 (windows; Windows 11 23H2)';

  setUp(() async {
    await AppUserAgentService.initialize(
      loadVersionInfo: () async =>
          const AppVersionInfo(version: '1.2.3', buildNumber: '7'),
      platform: 'windows',
      osVersion: 'Windows 11 23H2',
    );
  });

  tearDown(() {
    AppUserAgentService.debugSetUserAgentForTesting(null);
  });

  test('按约定格式生成应用身份 User-Agent', () {
    expect(HttpService.userAgent, expectedUserAgent);
    expect(
      AppUserAgentService.build(
        version: ' 1.2.3 beta ',
        platform: 'windows; desktop',
        osVersion: 'Windows\n11 (23H2)',
      ),
      'SSPU-AllinOne/1.2.3_beta (windows desktop; Windows 11 23H2)',
    );
  });

  test('HttpService 默认请求头使用统一应用 User-Agent', () async {
    final headers = HttpService.debugDefaultHeadersForTesting();

    expect(headers['User-Agent'], expectedUserAgent);
    expect(headers.values.join('\n'), isNot(contains('Mozilla/5.0')));
  });

  test('OA/CAS 相关 Dio 网关默认使用统一应用 User-Agent', () async {
    final gatewayDios = <Dio>[
      _buildDioForAcademicLoginGateway(),
      _buildDioForAcademicEamsGateway(),
      _buildDioForCampusCardGateway(),
      _buildDioForSportsAttendanceGateway(),
      _buildDioForStudentReportGateway(),
    ];

    for (final dio in gatewayDios) {
      final headers = await _captureDioHeaders(dio);
      expect(headers['User-Agent'], expectedUserAgent);
      expect(headers.values.join('\n'), isNot(contains('Mozilla/5.0')));
      expect(headers.values.join('\n'), isNot(contains('Chrome/')));
      expect(headers.values.join('\n'), isNot(contains('Firefox/')));
    }
  });

  test('微信公众号平台默认 User-Agent 保持浏览器标识', () {
    final config = WxmpConfig.defaults();

    expect(config.userAgent, contains('Mozilla/5.0'));
    expect(config.userAgent, contains('Chrome/114.0.0.0'));
    expect(config.userAgent, isNot(contains('SSPU-AllinOne/')));
  });
}

Future<Map<String, Object?>> _captureDioHeaders(Dio dio) async {
  final adapter = _HeaderCaptureAdapter();
  final originalAdapter = dio.httpClientAdapter;
  dio.httpClientAdapter = adapter;
  try {
    await dio.get<Object>('https://example.edu.cn/probe');
    return adapter.headers;
  } finally {
    dio.httpClientAdapter = originalAdapter;
  }
}

Dio _buildDioForAcademicLoginGateway() {
  final dio = Dio();
  DioAcademicLoginGateway(dio: dio);
  return dio;
}

Dio _buildDioForAcademicEamsGateway() {
  final dio = Dio();
  DioAcademicEamsGateway(dio: dio);
  return dio;
}

Dio _buildDioForCampusCardGateway() {
  final dio = Dio();
  DioCampusCardGateway(dio: dio);
  return dio;
}

Dio _buildDioForSportsAttendanceGateway() {
  final dio = Dio();
  DioSportsAttendanceGateway(dio: dio);
  return dio;
}

Dio _buildDioForStudentReportGateway() {
  final dio = Dio();
  DioStudentReportGateway(dio: dio);
  return dio;
}

class _HeaderCaptureAdapter implements HttpClientAdapter {
  Map<String, Object?> headers = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    headers = Map<String, Object?>.from(options.headers);
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
