import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sspu_allinone/models/mcp_access_audit.dart';
import 'package:sspu_allinone/services/mcp_access_audit_service.dart';
import 'package:sspu_allinone/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.debugUseSharedPreferencesStorageForTesting(true);
  });

  tearDown(() {
    StorageService.debugUseSharedPreferencesStorageForTesting(null);
  });

  test('audit keeps only the newest 200 redacted metadata entries', () async {
    final audit = McpAccessAuditService.instance;
    for (var i = 0; i < 205; i++) {
      await audit.append(
        McpAccessAudit(
          occurredAt: DateTime.utc(2026, 9, 11, 0, 0, i % 60),
          source: '127.0.0.1',
          capability: 'list_schedule_$i',
          allowed: true,
          outcome: 'ok',
          durationMs: i,
        ),
      );
    }

    final entries = await audit.read();
    expect(entries, hasLength(200));
    expect(entries.first.capability, 'list_schedule_5');
    expect(entries.last.capability, 'list_schedule_204');

    final encoded = jsonEncode(entries.map((entry) => entry.toJson()).toList());
    for (final forbidden in [
      'authorization',
      'bearer',
      'cookie',
      'password',
      'requestBody',
      'responseBody',
    ]) {
      expect(encoded.toLowerCase(), isNot(contains(forbidden.toLowerCase())));
    }
  });

  test(
    'serializes concurrent append operations without dropping entries',
    () async {
      final audit = McpAccessAuditService.instance;
      await Future.wait([
        for (var i = 0; i < 25; i++)
          audit.append(
            McpAccessAudit(
              occurredAt: DateTime.utc(2026, 9, 11, 0, 0, i),
              source: '127.0.0.1',
              capability: 'tool_$i',
              allowed: true,
              outcome: 'ok',
              durationMs: i,
            ),
          ),
      ]);
      final entries = await audit.read();
      expect(entries, hasLength(25));
      expect(entries.map((entry) => entry.capability), contains('tool_24'));
    },
  );
}
