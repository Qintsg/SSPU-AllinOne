/// Tracks the identity/data context observed by in-flight MCP calls.
///
/// The value is deliberately process-local. Persisting it would not add a
/// security boundary because a process restart already cancels every call.
class McpExecutionContextService {
  McpExecutionContextService();

  static final McpExecutionContextService instance =
      McpExecutionContextService();

  int _generation = 0;

  int capture() => _generation;

  bool isCurrent(int generation) => generation == _generation;

  void invalidate() {
    _generation++;
  }
}
