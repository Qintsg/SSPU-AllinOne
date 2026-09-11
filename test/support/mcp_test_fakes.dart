import 'package:sspu_allinone/services/mcp_snapshot_adapters.dart';

/// Deterministic, offline-only snapshots used by MCP protocol tests.
class FakeMcpSnapshotAdapters extends McpSnapshotAdapters {
  FakeMcpSnapshotAdapters({
    Map<String, McpSnapshotEnvelope>? values,
    Map<String, Future<McpSnapshotEnvelope> Function()>? handlers,
  }) : values = values ?? const {},
       handlers = handlers ?? const {};

  final Map<String, McpSnapshotEnvelope> values;
  final Map<String, Future<McpSnapshotEnvelope> Function()> handlers;
  final Map<String, int> calls = {};

  Future<McpSnapshotEnvelope> _read(String name) async {
    calls[name] = (calls[name] ?? 0) + 1;
    final handler = handlers[name];
    if (handler != null) return handler();
    return values[name] ?? const McpSnapshotEnvelope(status: 'empty');
  }

  @override
  Future<McpSnapshotEnvelope> profile() => _read('profile');

  @override
  Future<McpSnapshotEnvelope> schedule() => _read('schedule');

  @override
  Future<McpSnapshotEnvelope> grades() => _read('grades');

  @override
  Future<McpSnapshotEnvelope> exams() => _read('exams');

  @override
  Future<McpSnapshotEnvelope> program() => _read('program');

  @override
  Future<McpSnapshotEnvelope> secondClassroom() => _read('secondClassroom');

  @override
  Future<McpSnapshotEnvelope> campusCard() => _read('campusCard');

  @override
  Future<McpSnapshotEnvelope> campusCardTransactions(
    Map<String, dynamic> args,
  ) => _read('campusCardTransactions');

  @override
  Future<McpSnapshotEnvelope> messages(Map<String, dynamic> args) =>
      _read('messages');

  @override
  Future<McpSnapshotEnvelope> email(Map<String, dynamic> args) =>
      _read('email');
}
