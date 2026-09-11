import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/mcp_authorization.dart';
import 'package:sspu_allinone/models/mcp_server_config.dart';
import 'package:sspu_allinone/services/mcp_authorization_service.dart';
import 'package:sspu_allinone/services/mcp_capability_registry.dart';
import 'package:sspu_allinone/services/mcp_server_auth_service.dart';
import 'package:sspu_allinone/services/mcp_server_controller.dart';
import 'package:sspu_allinone/services/mcp_snapshot_adapters.dart';
import 'package:sspu_allinone/services/storage_service.dart';

import 'support/mcp_test_fakes.dart';

void main() {
  test('raw HTTP client interoperates without importing mcp_dart', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    final authorization = McpAuthorizationService.instance;
    await authorization.clear();
    await authorization.setGrant(McpDataDomain.schedule, true);
    final auth = McpServerAuthService.instance;
    final firstKey = await auth.generate();
    final registry = McpCapabilityRegistry(
      authorization: authorization,
      adapters: FakeMcpSnapshotAdapters(
        values: {
          'schedule': McpSnapshotEnvelope(
            status: 'stale',
            snapshotAt: DateTime.utc(2026, 9, 11),
            data: {
              'items': [
                {'courseName': '高等数学'},
                {'courseName': '大学英语'},
              ],
            },
          ),
        },
      ),
    );
    final reservation = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final port = reservation.port;
    await reservation.close();
    final controller = McpServerController(
      auth: auth,
      authorization: authorization,
      registry: registry,
    );
    await controller.saveConfig(
      McpServerConfig(enabled: true, port: port, apiKeyEnabled: true),
    );
    await controller.start();
    final client = _RawMcpHttpClient(
      Uri.parse(controller.state.endpoint!),
      firstKey,
    );
    addTearDown(() async {
      client.close();
      await controller.disposeServer();
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
    });

    final initialized = await client.request('server/discover', {});
    expect(initialized.statusCode, HttpStatus.ok);
    expect(initialized.result, isNotNull, reason: 'error=${initialized.error}');
    expect(
      initialized.result,
      containsPair('supportedVersions', contains('2026-07-28')),
    );

    final listed = await client.request('tools/list', <String, dynamic>{});
    final tools = listed.result?['tools'] as List<dynamic>;
    expect(tools.map((tool) => tool['name']), contains('list_schedule'));
    expect(tools.map((tool) => tool['name']), isNot(contains('list_grades')));

    final firstPage = await client.request('tools/call', {
      'name': 'list_schedule',
      'arguments': {'limit': 1},
    });
    final firstContent = firstPage.result?['structuredContent'];
    expect(firstContent['status'], 'stale');
    expect(firstContent['data']['items'], hasLength(1));
    final cursor = firstContent['page']['nextCursor'] as String;

    final secondPage = await client.request('tools/call', {
      'name': 'list_schedule',
      'arguments': {'limit': 1, 'cursor': cursor},
    });
    expect(secondPage.result?['structuredContent']['data']['items'].single, {
      'courseName': '大学英语',
    });

    final denied = await client.request('tools/call', {
      'name': 'list_grades',
      'arguments': <String, dynamic>{},
    });
    expect(
      denied.result?['isError'] == true || denied.error != null,
      isTrue,
      reason:
          'result=${denied.result}, error=${denied.error}, body=${denied.body}',
    );

    final secondKey = await auth.rotate();
    final rejected = await client.request('tools/list', <String, dynamic>{});
    expect(rejected.statusCode, HttpStatus.unauthorized);
    client.apiKey = secondKey;
    final relisted = await client.request('tools/list', <String, dynamic>{});
    expect(relisted.statusCode, HttpStatus.ok);
  });
}

class _RawMcpHttpClient {
  _RawMcpHttpClient(this.endpoint, this.apiKey);

  final Uri endpoint;
  String apiKey;
  final HttpClient _client = HttpClient();
  int _id = 0;
  String? _sessionId;

  Future<_RawMcpResponse> request(
    String method,
    Map<String, dynamic> params,
  ) async {
    final request = await _client.postUrl(endpoint);
    request.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.acceptHeader, 'application/json, text/event-stream')
      ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.headers.set('mcp-protocol-version', '2026-07-28');
    request.headers.set('mcp-method', method);
    final requestName = params['name'];
    if (method == 'tools/call' && requestName is String) {
      request.headers.set('mcp-name', requestName);
    }
    if (_sessionId != null) {
      request.headers.set('mcp-session-id', _sessionId!);
    }
    request.write(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': ++_id,
        'method': method,
        'params': {
          ...params,
          '_meta': {
            'io.modelcontextprotocol/protocolVersion': '2026-07-28',
            'io.modelcontextprotocol/clientCapabilities': <String, dynamic>{},
            'io.modelcontextprotocol/clientInfo': {
              'name': 'raw-http-acceptance',
              'version': '1.0.0',
            },
          },
        },
      }),
    );
    final response = await request.close();
    _sessionId ??= response.headers.value('mcp-session-id');
    final body = await utf8.decoder.bind(response).join();
    if (body.isEmpty) {
      return _RawMcpResponse(statusCode: response.statusCode, body: body);
    }
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return _RawMcpResponse(
      statusCode: response.statusCode,
      result: decoded['result'] as Map<String, dynamic>?,
      error: decoded['error'],
      body: body,
    );
  }

  void close() => _client.close(force: true);
}

class _RawMcpResponse {
  const _RawMcpResponse({
    required this.statusCode,
    this.result,
    this.error,
    this.body,
  });

  final int statusCode;
  final Map<String, dynamic>? result;
  final Object? error;
  final String? body;
}
