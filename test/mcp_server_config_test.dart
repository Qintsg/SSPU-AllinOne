import 'package:flutter_test/flutter_test.dart';
import 'package:sspu_allinone/models/mcp_authorization.dart';
import 'package:sspu_allinone/models/mcp_server_config.dart';

void main() {
  test('MCP defaults are safe and LAN always requires a key', () {
    const defaults = McpServerConfig();
    expect(defaults.enabled, isFalse);
    expect(defaults.accessScope, McpAccessScope.loopback);
    expect(defaults.apiKeyEnabled, isTrue);
    expect(defaults.canStart, isTrue);

    final lan = defaults.copyWith(
      accessScope: McpAccessScope.lan,
      lanRiskAcceptedAt: DateTime(2026, 9, 11),
      apiKeyEnabled: false,
    );
    expect(lan.apiKeyEnabled, isFalse);
    expect(lan.canStart, isFalse);
    final decoded = McpServerConfig.fromJson(lan.toJson());
    expect(decoded.apiKeyEnabled, isTrue);
  });

  test('authorization grants are default deny and versioned', () {
    const empty = McpAuthorization();
    expect(empty.isAllowed(McpDataDomain.grades), isFalse);
    final next = empty.set(McpDataDomain.grades, true);
    expect(next.isAllowed(McpDataDomain.grades), isTrue);
    expect(next.version, 1);
    final restored = McpAuthorization.fromJson(next.toJson());
    expect(restored.isAllowed(McpDataDomain.grades), isTrue);
    expect(restored.version, 1);
  });
}
