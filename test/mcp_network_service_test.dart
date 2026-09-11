import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/mcp_server_config.dart';
import 'package:sspu_allinone/services/mcp_network_service.dart';
import 'package:sspu_allinone/services/mcp_server_controller.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  test('private IPv4 classifier accepts only RFC1918 ranges', () {
    const network = McpNetworkService();
    for (final address in [
      '10.0.0.1',
      '172.16.0.1',
      '172.31.255.254',
      '192.168.1.2',
    ]) {
      expect(network.isPrivateIpv4(address), isTrue, reason: address);
    }
    for (final address in [
      '127.0.0.1',
      '169.254.1.1',
      '172.32.0.1',
      '8.8.8.8',
      'bad',
    ]) {
      expect(network.isPrivateIpv4(address), isFalse, reason: address);
    }
  });

  test(
    'Host and Origin outside the allowlist are rejected before MCP parsing',
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
      addTearDown(() async {
        await controller.disposeServer();
        StorageService.debugUseSharedPreferencesStorageForTesting(null);
      });

      final badHost = await _post(
        controller.state.endpoint!,
        headers: {'Host': 'evil.example'},
      );
      expect(badHost, HttpStatus.forbidden);

      final browserOrigin = await _post(
        controller.state.endpoint!,
        headers: {'Origin': 'https://evil.example'},
      );
      expect(browserOrigin, HttpStatus.forbidden);

      expect(
        await _request(controller.state.endpoint!, method: 'GET'),
        HttpStatus.methodNotAllowed,
      );
      expect(
        await _request('${controller.state.endpoint!}/missing'),
        HttpStatus.notFound,
      );

      final oversized = utf8.encode('x' * (256 * 1024 + 1));
      expect(
        await _request(controller.state.endpoint!, bytes: oversized),
        HttpStatus.requestEntityTooLarge,
      );

      final burstStatuses = <int>[];
      for (var i = 0; i < 11; i++) {
        burstStatuses.add(await _post(controller.state.endpoint!));
      }
      expect(burstStatuses.last, HttpStatus.tooManyRequests);
    },
  );
}

Future<int> _post(
  String endpoint, {
  Map<String, String> headers = const {},
}) async {
  return _request(
    endpoint,
    headers: headers,
    bytes: utf8.encode(
      jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'ping'}),
    ),
  );
}

Future<int> _request(
  String endpoint, {
  String method = 'POST',
  Map<String, String> headers = const {},
  List<int>? bytes,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, Uri.parse(endpoint));
    if (method == 'POST') request.headers.contentType = ContentType.json;
    headers.forEach(request.headers.set);
    if (bytes != null) {
      request.contentLength = bytes.length;
      request.add(bytes);
    }
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}
