import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/mcp_server_config.dart';
import 'package:sspu_allinone/services/mcp_server_controller.dart';
import 'package:sspu_allinone/services/mcp_network_service.dart';
import 'package:sspu_allinone/services/mcp_server_auth_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  test(
    'loopback MCP server starts, negotiates, and releases the port',
    () async {
      SharedPreferences.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      final reservation = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = reservation.port;
      await reservation.close();

      final controller = McpServerController();
      await controller.saveConfig(
        McpServerConfig(enabled: true, port: port, apiKeyEnabled: false),
      );
      await controller.start();
      expect(controller.state.isRunning, isTrue);

      final client = McpClient(
        const Implementation(name: 'sspu-test', version: '1.0.0'),
        options: const McpClientOptions(protocol: McpProtocol.require2026),
      );
      await client.connect(
        StreamableHttpClientTransport(Uri.parse(controller.state.endpoint!)),
      );
      final tools = await client.listTools();
      expect(tools.tools, isEmpty);
      await client.close();
      await controller.stop();

      final rebound = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port,
      );
      await rebound.close();
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
    },
  );

  test(
    'persisting disabled config stops an active listener without restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      final reservation = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = reservation.port;
      await reservation.close();

      final controller = McpServerController();
      await controller.saveConfig(
        McpServerConfig(enabled: true, port: port, apiKeyEnabled: false),
      );
      await controller.start();
      expect(controller.state.isRunning, isTrue);

      await controller.saveConfig(
        McpServerConfig(enabled: false, port: port, apiKeyEnabled: false),
      );
      expect(controller.state.isRunning, isFalse);

      final rebound = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port,
      );
      await rebound.close();
      await controller.disposeServer();
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
    },
  );

  test(
    'LAN mode binds all interfaces and publishes a real private endpoint',
    () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      final reservation = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = reservation.port;
      await reservation.close();
      final auth = McpServerAuthService.instance;
      final key = await auth.generate();
      final controller = McpServerController(
        auth: auth,
        network: _FakeMcpNetwork(const ['192.168.50.10']),
      );
      await controller.saveConfig(
        McpServerConfig(
          enabled: true,
          port: port,
          accessScope: McpAccessScope.lan,
          lanRiskAcceptedAt: DateTime(2026, 9, 11),
          apiKeyEnabled: true,
        ),
      );
      await controller.start();
      addTearDown(() async {
        await controller.disposeServer();
        StorageService.debugUseSharedPreferencesStorageForTesting(null);
      });

      expect(controller.state.isRunning, isTrue);
      expect(controller.state.bindAddress, '0.0.0.0');
      expect(controller.state.endpoint, 'http://192.168.50.10:$port/mcp');

      // The test host can reach the all-interface listener through loopback;
      // the advertised URL deliberately remains the private LAN address.
      final client = McpClient(
        const Implementation(name: 'lan-test', version: '1.0.0'),
        options: const McpClientOptions(protocol: McpProtocol.require2026),
      );
      addTearDown(client.close);
      final localEndpoint = controller.state.endpoint!.replaceFirst(
        '192.168.50.10',
        '127.0.0.1',
      );
      await client.connect(
        StreamableHttpClientTransport(
          Uri.parse(localEndpoint),
          opts: StreamableHttpClientTransportOptions(
            requestInit: {
              'headers': {'Authorization': 'Bearer $key'},
            },
          ),
        ),
      );
      expect((await client.listTools()).tools, isEmpty);
    },
  );

  test('port conflict fails closed with an actionable error', () async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    final reservation = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final controller = McpServerController();
    addTearDown(() async {
      await reservation.close();
      await controller.disposeServer();
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
    });

    await controller.saveConfig(
      McpServerConfig(
        enabled: true,
        port: reservation.port,
        apiKeyEnabled: false,
      ),
    );
    await controller.start();

    expect(controller.state.isRunning, isFalse);
    expect(controller.state.errorMessage, contains('端口不可用'));
  });
}

class _FakeMcpNetwork extends McpNetworkService {
  _FakeMcpNetwork(this.addresses) : super();

  final List<String> addresses;

  @override
  Future<List<String>> privateIpv4Addresses() async => addresses;
}
