import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/mcp_server_config.dart';
import 'package:sspu_allinone/services/mcp_server_auth_service.dart';
import 'package:sspu_allinone/services/mcp_server_controller.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  test('Bearer key is required and rotation invalidates the old key', () async {
    final auth = McpServerAuthService.instance;
    final firstKey = await auth.generate();
    final controller = await _startAuthenticatedController(auth);
    addTearDown(controller.disposeServer);

    final missing = _client(controller.state.endpoint!);
    addTearDown(missing.close);
    await expectLater(
      missing.connect(_transport(controller.state.endpoint!)),
      throwsA(isA<McpError>()),
    );
    expect(
      await _rawStatus(controller.state.endpoint!),
      HttpStatus.unauthorized,
    );

    final valid = _client(controller.state.endpoint!);
    addTearDown(valid.close);
    await valid.connect(_transport(controller.state.endpoint!, key: firstKey));
    expect((await valid.listTools()).tools, isEmpty);

    final secondKey = await auth.rotate();
    await expectLater(valid.listTools(), throwsA(isA<McpError>()));

    final rotated = _client(controller.state.endpoint!);
    addTearDown(rotated.close);
    await rotated.connect(
      _transport(controller.state.endpoint!, key: secondKey),
    );
    expect((await rotated.listTools()).tools, isEmpty);
  });
}

Future<McpServerController> _startAuthenticatedController(
  McpServerAuthService auth,
) async {
  final reservation = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = reservation.port;
  await reservation.close();
  final controller = McpServerController(auth: auth);
  await controller.saveConfig(
    McpServerConfig(enabled: true, port: port, apiKeyEnabled: true),
  );
  await controller.start();
  expect(controller.state.isRunning, isTrue);
  return controller;
}

McpClient _client(String endpoint) => McpClient(
  const Implementation(name: 'auth-test', version: '1.0.0'),
  options: const McpClientOptions(protocol: McpProtocol.require2026),
);

StreamableHttpClientTransport _transport(String endpoint, {String? key}) =>
    StreamableHttpClientTransport(
      Uri.parse(endpoint),
      opts: StreamableHttpClientTransportOptions(
        requestInit: key == null
            ? const {}
            : {
                'headers': {'Authorization': 'Bearer $key'},
              },
      ),
    );

Future<int> _rawStatus(String endpoint) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(endpoint));
    request.headers.contentType = ContentType.json;
    request.write('{}');
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}
