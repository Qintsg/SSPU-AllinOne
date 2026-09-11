import 'dart:convert';

import '../models/mcp_authorization.dart';
import 'storage_service.dart';

class McpAuthorizationService {
  McpAuthorizationService._();
  static final instance = McpAuthorizationService._();

  Future<McpAuthorization> read() async {
    final raw = await StorageService.getString(StorageKeys.mcpAuthorization);
    if (raw == null || raw.isEmpty) return const McpAuthorization();
    try {
      return McpAuthorization.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const McpAuthorization();
    }
  }

  Future<McpAuthorization> setGrant(McpDataDomain domain, bool enabled) async {
    final next = (await read()).set(domain, enabled);
    await StorageService.setString(
      StorageKeys.mcpAuthorization,
      jsonEncode(next.toJson()),
    );
    return next;
  }

  Future<void> clear() => StorageService.remove(StorageKeys.mcpAuthorization);
}
