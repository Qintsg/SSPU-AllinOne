import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_dart/mcp_dart.dart';
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
  test(
    '100 fresh or upgraded disabled starts never open an MCP listener',
    () async {
      for (var run = 0; run < 100; run++) {
        SharedPreferences.setMockInitialValues({});
        StorageService.debugUseSharedPreferencesStorageForTesting(true);
        final controller = McpServerController(platformSupported: true);
        await controller.loadConfig();
        await controller.start();
        expect(controller.state.isRunning, isFalse, reason: 'run $run');
        expect(controller.state.endpoint, isNull, reason: 'run $run');
        await controller.disposeServer();
      }
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
    },
  );

  test(
    'enable, copy endpoint, and discover an authorized capability in under two minutes',
    () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      final authorization = McpAuthorizationService.instance;
      await authorization.clear();
      await authorization.setGrant(McpDataDomain.schedule, true);
      final auth = McpServerAuthService.instance;
      final key = await auth.generate();
      final reservation = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = reservation.port;
      await reservation.close();
      final controller = McpServerController(
        auth: auth,
        authorization: authorization,
        registry: McpCapabilityRegistry(
          authorization: authorization,
          adapters: FakeMcpSnapshotAdapters(),
        ),
      );
      final stopwatch = Stopwatch()..start();
      await controller.saveConfig(
        McpServerConfig(enabled: true, port: port, apiKeyEnabled: true),
      );
      await controller.start();
      final client = McpClient(
        const Implementation(name: 'timed-acceptance', version: '1.0.0'),
        options: const McpClientOptions(protocol: McpProtocol.require2026),
      );
      await client.connect(
        StreamableHttpClientTransport(
          Uri.parse(controller.state.endpoint!),
          opts: StreamableHttpClientTransportOptions(
            requestInit: {
              'headers': {'Authorization': 'Bearer $key'},
            },
          ),
        ),
      );
      final tools = await client.listTools();
      stopwatch.stop();
      expect(tools.tools.map((tool) => tool.name), contains('list_schedule'));
      expect(stopwatch.elapsed, lessThan(const Duration(minutes: 2)));
      await client.close();
      await controller.disposeServer();
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
    },
  );

  test(
    'p95 first-result latency stays below 500 ms for up to 100 cached records',
    () async {
      SharedPreferences.setMockInitialValues({});
      StorageService.debugUseSharedPreferencesStorageForTesting(true);
      final authorization = McpAuthorizationService.instance;
      await authorization.clear();
      await authorization.setGrant(McpDataDomain.schedule, true);
      final items = List.generate(100, (index) => {'courseName': '课程 $index'});
      final reservation = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = reservation.port;
      await reservation.close();
      final controller = McpServerController(
        authorization: authorization,
        registry: McpCapabilityRegistry(
          authorization: authorization,
          adapters: FakeMcpSnapshotAdapters(
            values: {
              'schedule': McpSnapshotEnvelope(
                status: 'ok',
                data: {'items': items},
              ),
            },
          ),
        ),
      );
      await controller.saveConfig(
        McpServerConfig(enabled: true, port: port, apiKeyEnabled: false),
      );
      await controller.start();
      final client = McpClient(
        const Implementation(name: 'performance-acceptance', version: '1.0.0'),
        options: const McpClientOptions(protocol: McpProtocol.require2026),
      );
      await client.connect(
        StreamableHttpClientTransport(Uri.parse(controller.state.endpoint!)),
      );
      final timings = <int>[];
      for (var index = 0; index < 20; index++) {
        final watch = Stopwatch()..start();
        final result = await client.callTool(
          const CallToolRequest(
            name: 'list_schedule',
            arguments: {'limit': 100},
          ),
        );
        watch.stop();
        expect(result.isError, isNot(true));
        timings.add(watch.elapsedMicroseconds);
        // Respect the production 60/minute token bucket while collecting the
        // latency sample; pacing avoids measuring an intentional 429 response.
        if (index + 1 < 20) {
          await Future<void>.delayed(const Duration(milliseconds: 1000));
        }
      }
      timings.sort();
      final p95 = timings[(timings.length * .95).ceil() - 1];
      expect(p95, lessThan(500000));
      await client.close();
      await controller.disposeServer();
      StorageService.debugUseSharedPreferencesStorageForTesting(null);
    },
  );
}
