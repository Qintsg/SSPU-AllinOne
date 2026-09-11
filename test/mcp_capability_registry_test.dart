import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/mcp_authorization.dart';
import 'package:sspu_allinone/models/mcp_server_config.dart';
import 'package:sspu_allinone/services/mcp_authorization_service.dart';
import 'package:sspu_allinone/services/mcp_capability_registry.dart';
import 'package:sspu_allinone/services/mcp_execution_context_service.dart';
import 'package:sspu_allinone/services/mcp_server_controller.dart';
import 'package:sspu_allinone/services/mcp_snapshot_adapters.dart';
import 'package:sspu_allinone/services/storage_service.dart';

import 'support/mcp_test_fakes.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
    await McpAuthorizationService.instance.clear();
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  test(
    'discovery exposes only granted domains and calls return paged snapshots',
    () async {
      final adapters = FakeMcpSnapshotAdapters(
        values: {
          'schedule': McpSnapshotEnvelope(
            status: 'stale',
            snapshotAt: DateTime.utc(2026, 9, 9),
            data: {
              'items': [
                {'courseName': '高等数学'},
                {'courseName': '大学英语'},
              ],
            },
          ),
        },
      );
      final authorization = McpAuthorizationService.instance;
      await authorization.setGrant(McpDataDomain.schedule, true);
      await authorization.setGrant(McpDataDomain.messages, true);
      await authorization.setGrant(McpDataDomain.email, true);
      expect(
        await StorageService.getString(StorageKeys.mcpAuthorization),
        contains('schedule'),
      );
      expect(
        (await authorization.read()).isAllowed(McpDataDomain.schedule),
        isTrue,
      );
      final registry = McpCapabilityRegistry(
        adapters: adapters,
        authorization: authorization,
      );
      final controller = await _startController(registry, authorization);
      final client = await _connect(controller.state.endpoint!);
      addTearDown(() async {
        await client.close();
        await controller.disposeServer();
      });

      final names = (await client.listTools()).tools
          .map((tool) => tool.name)
          .toSet();
      expect(
        names,
        containsAll(['list_schedule', 'search_messages', 'search_email']),
      );
      expect(names, isNot(contains('list_grades')));

      final first = await client.callTool(
        const CallToolRequest(name: 'list_schedule', arguments: {'limit': 1}),
      );
      expect(first.isError, isNot(true));
      expect(first.structuredContent?['status'], 'stale');
      final firstPage =
          first.structuredContent?['page'] as Map<String, dynamic>;
      expect(firstPage['hasMore'], isTrue);
      final cursor = firstPage['nextCursor'] as String;
      final firstItems =
          (first.structuredContent?['data'] as Map<String, dynamic>)['items']
              as List<dynamic>;
      expect(firstItems.single, {'courseName': '高等数学'});

      final second = await client.callTool(
        CallToolRequest(
          name: 'list_schedule',
          arguments: {'limit': 1, 'cursor': cursor},
        ),
      );
      final secondItems =
          (second.structuredContent?['data'] as Map<String, dynamic>)['items']
              as List<dynamic>;
      expect(secondItems.single, {'courseName': '大学英语'});

      final tampered = await client.callTool(
        CallToolRequest(
          name: 'list_schedule',
          arguments: {'limit': 1, 'cursor': '${cursor}x'},
        ),
      );
      expect(tampered.isError, isTrue);
      expect(
        tampered.content.whereType<TextContent>().single.text,
        contains('分页游标无效'),
      );

      final invalidRange = await client.callTool(
        const CallToolRequest(
          name: 'search_messages',
          arguments: {'from': 'not-a-date'},
        ),
      );
      expect(invalidRange.isError, isTrue);
      expect(
        invalidRange.content.whereType<TextContent>().single.text,
        contains('查询参数无效'),
      );
    },
  );

  test('authorization changed during a call discards the snapshot', () async {
    final started = Completer<void>();
    final release = Completer<McpSnapshotEnvelope>();
    final adapters = FakeMcpSnapshotAdapters(
      handlers: {
        'profile': () {
          if (!started.isCompleted) started.complete();
          return release.future;
        },
      },
    );
    final authorization = McpAuthorizationService.instance;
    await authorization.setGrant(McpDataDomain.profile, true);
    expect(
      (await authorization.read()).isAllowed(McpDataDomain.profile),
      isTrue,
    );
    final registry = McpCapabilityRegistry(
      adapters: adapters,
      authorization: authorization,
    );
    final controller = await _startController(registry, authorization);
    final client = await _connect(controller.state.endpoint!);
    addTearDown(() async {
      await client.close();
      await controller.disposeServer();
    });

    final pending = client.callTool(
      const CallToolRequest(name: 'get_current_profile'),
    );
    await started.future;
    await authorization.setGrant(McpDataDomain.profile, false);
    release.complete(
      const McpSnapshotEnvelope(status: 'ok', data: {'displayName': '不应返回'}),
    );

    final result = await pending;
    expect(result.isError, isTrue);
    expect(result.structuredContent, isNull);
    expect(
      result.content.whereType<TextContent>().single.text,
      contains('授权上下文已变化'),
    );
  });

  test(
    'account or data context changed during a call discards the snapshot',
    () async {
      final started = Completer<void>();
      final release = Completer<McpSnapshotEnvelope>();
      final context = McpExecutionContextService();
      final adapters = FakeMcpSnapshotAdapters(
        handlers: {
          'profile': () {
            if (!started.isCompleted) started.complete();
            return release.future;
          },
        },
      );
      final authorization = McpAuthorizationService.instance;
      await authorization.setGrant(McpDataDomain.profile, true);
      final registry = McpCapabilityRegistry(
        adapters: adapters,
        authorization: authorization,
        executionContext: context,
      );
      final controller = await _startController(registry, authorization);
      final client = await _connect(controller.state.endpoint!);
      addTearDown(() async {
        await client.close();
        await controller.disposeServer();
      });

      final pending = client.callTool(
        const CallToolRequest(name: 'get_current_profile'),
      );
      await started.future;
      context.invalidate();
      release.complete(
        const McpSnapshotEnvelope(status: 'ok', data: {'displayName': '旧账号'}),
      );

      final result = await pending;
      expect(result.isError, isTrue);
      expect(result.structuredContent, isNull);
      expect(
        result.content.whereType<TextContent>().single.text,
        contains('数据上下文已变化'),
      );
    },
  );

  test('empty snapshots remain successful and distinguishable', () async {
    final authorization = McpAuthorizationService.instance;
    await authorization.setGrant(McpDataDomain.profile, true);
    final registry = McpCapabilityRegistry(
      adapters: FakeMcpSnapshotAdapters(),
      authorization: authorization,
    );
    final controller = await _startController(registry, authorization);
    final client = await _connect(controller.state.endpoint!);
    addTearDown(() async {
      await client.close();
      await controller.disposeServer();
    });

    final result = await client.callTool(
      const CallToolRequest(name: 'get_current_profile'),
    );
    expect(result.isError, isNot(true));
    expect(result.structuredContent?['status'], 'empty');
  });

  test('a fifth concurrent capability call is rejected', () async {
    final started = Completer<void>();
    final releases = List.generate(4, (_) => Completer<McpSnapshotEnvelope>());
    var callIndex = 0;
    final adapters = FakeMcpSnapshotAdapters(
      handlers: {
        'profile': () {
          final index = callIndex++;
          if (index == 3 && !started.isCompleted) started.complete();
          return releases[index].future;
        },
      },
    );
    final authorization = McpAuthorizationService.instance;
    await authorization.setGrant(McpDataDomain.profile, true);
    final registry = McpCapabilityRegistry(
      adapters: adapters,
      authorization: authorization,
    );
    final controller = await _startController(registry, authorization);
    final clients = <McpClient>[];
    for (var index = 0; index < 5; index++) {
      clients.add(await _connect(controller.state.endpoint!));
    }
    addTearDown(() async {
      for (final client in clients) {
        await client.close();
      }
      await controller.disposeServer();
    });

    final pending = clients
        .take(4)
        .map(
          (client) => client.callTool(
            const CallToolRequest(name: 'get_current_profile'),
          ),
        )
        .toList();
    await started.future;
    final rejected = await clients.last.callTool(
      const CallToolRequest(name: 'get_current_profile'),
    );
    expect(rejected.isError, isTrue);
    expect(
      rejected.content.whereType<TextContent>().single.text,
      contains('并发请求过多'),
    );
    for (final release in releases) {
      release.complete(const McpSnapshotEnvelope(status: 'empty'));
    }
    await Future.wait(pending);
  });

  test('snapshot timeout returns a stable timeout result', () async {
    final never = Completer<McpSnapshotEnvelope>();
    final authorization = McpAuthorizationService.instance;
    await authorization.setGrant(McpDataDomain.profile, true);
    final registry = McpCapabilityRegistry(
      adapters: FakeMcpSnapshotAdapters(
        handlers: {'profile': () => never.future},
      ),
      authorization: authorization,
      toolTimeout: const Duration(milliseconds: 20),
    );
    final controller = await _startController(registry, authorization);
    final client = await _connect(controller.state.endpoint!);
    addTearDown(() async {
      await client.close();
      await controller.disposeServer();
    });

    final result = await client.callTool(
      const CallToolRequest(name: 'get_current_profile'),
    );
    expect(result.isError, isTrue);
    expect(
      result.content.whereType<TextContent>().single.text,
      contains('读取本地快照超时'),
    );
  });

  test(
    'oversized tool results are rejected before transport response',
    () async {
      final authorization = McpAuthorizationService.instance;
      await authorization.setGrant(McpDataDomain.profile, true);
      final registry = McpCapabilityRegistry(
        adapters: FakeMcpSnapshotAdapters(
          values: {
            'profile': McpSnapshotEnvelope(
              status: 'ok',
              data: {'displayName': 'x' * 1024},
            ),
          },
        ),
        authorization: authorization,
        maxResponseBytes: 256,
      );
      final controller = await _startController(registry, authorization);
      final client = await _connect(controller.state.endpoint!);
      addTearDown(() async {
        await client.close();
        await controller.disposeServer();
      });

      final result = await client.callTool(
        const CallToolRequest(name: 'get_current_profile'),
      );
      expect(result.isError, isTrue);
      expect(
        result.content.whereType<TextContent>().single.text,
        contains('结果过大'),
      );
    },
  );
}

Future<McpServerController> _startController(
  McpCapabilityRegistry registry,
  McpAuthorizationService authorization,
) async {
  final reservation = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = reservation.port;
  await reservation.close();
  final controller = McpServerController(
    authorization: authorization,
    registry: registry,
  );
  await controller.saveConfig(
    McpServerConfig(enabled: true, port: port, apiKeyEnabled: false),
  );
  await controller.start();
  expect(controller.state.isRunning, isTrue);
  return controller;
}

Future<McpClient> _connect(String endpoint) async {
  final client = McpClient(
    const Implementation(name: 'registry-test', version: '1.0.0'),
    options: const McpClientOptions(protocol: McpProtocol.require2026),
  );
  await client.connect(StreamableHttpClientTransport(Uri.parse(endpoint)));
  return client;
}
