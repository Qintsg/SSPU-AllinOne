import 'mcp_server_config.dart';

enum McpServerPhase { stopped, starting, running, stopping, failed }

class McpServerState {
  const McpServerState({
    this.phase = McpServerPhase.stopped,
    this.bindAddress,
    this.port,
    this.endpoint,
    this.errorMessage,
    this.generation = 0,
    this.lastAccessAt,
  });

  final McpServerPhase phase;
  final String? bindAddress;
  final int? port;
  final String? endpoint;
  final String? errorMessage;
  final int generation;
  final DateTime? lastAccessAt;

  bool get isRunning => phase == McpServerPhase.running;
  bool get isBusy =>
      phase == McpServerPhase.starting || phase == McpServerPhase.stopping;

  McpServerState copyWith({
    McpServerPhase? phase,
    String? bindAddress,
    int? port,
    String? endpoint,
    String? errorMessage,
    int? generation,
    DateTime? lastAccessAt,
    bool clearError = false,
  }) => McpServerState(
    phase: phase ?? this.phase,
    bindAddress: bindAddress ?? this.bindAddress,
    port: port ?? this.port,
    endpoint: endpoint ?? this.endpoint,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    generation: generation ?? this.generation,
    lastAccessAt: lastAccessAt ?? this.lastAccessAt,
  );
}

String mcpBindAddress(McpAccessScope scope) =>
    scope == McpAccessScope.lan ? '0.0.0.0' : '127.0.0.1';
