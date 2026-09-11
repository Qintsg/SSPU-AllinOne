import 'dart:convert';

import '../models/mcp_access_audit.dart';
import 'storage_service.dart';

class McpAccessAuditService {
  McpAccessAuditService._();
  static final instance = McpAccessAuditService._();
  static const maxEntries = 200;
  // Serialize read-modify-write operations so simultaneous MCP requests do
  // not overwrite each other's audit entries.
  Future<void> _writeQueue = Future<void>.value();

  Future<List<McpAccessAudit>> read() async {
    final raw = await StorageService.getString(StorageKeys.mcpAccessAudit);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(McpAccessAudit.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> append(McpAccessAudit entry) {
    final operation = _writeQueue.then<void>((_) async {
      await _appendInternal(entry);
    });
    _writeQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }

  Future<void> _appendInternal(McpAccessAudit entry) async {
    final entries = await read();
    final next = [...entries, entry];
    final kept = next.length > maxEntries
        ? next.sublist(next.length - maxEntries)
        : next;
    await StorageService.setString(
      StorageKeys.mcpAccessAudit,
      jsonEncode(kept.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() {
    final operation = _writeQueue.then<void>(
      (_) => StorageService.remove(StorageKeys.mcpAccessAudit),
    );
    _writeQueue = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }
}
