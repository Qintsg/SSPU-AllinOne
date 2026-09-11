import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/mcp_authorization.dart';
import '../models/mcp_server_config.dart';
import '../models/mcp_server_state.dart';
import 'mcp_access_audit_service.dart';
import 'mcp_authorization_service.dart';
import 'mcp_capability_registry.dart';
import 'mcp_http_server_host.dart';
import 'mcp_network_service.dart';
import 'mcp_server_auth_service.dart';
import 'storage_service.dart';

class McpServerController extends ChangeNotifier {
  McpServerController({
    McpServerAuthService? auth,
    McpAuthorizationService? authorization,
    McpCapabilityRegistry? registry,
    McpNetworkService? network,
    bool? platformSupported,
  }) : auth = auth ?? McpServerAuthService.instance,
       authorization = authorization ?? McpAuthorizationService.instance,
       registry =
           registry ??
           McpCapabilityRegistry(
             authorization: authorization ?? McpAuthorizationService.instance,
           ),
       network = network ?? const McpNetworkService(),
       _platformSupportedOverride = platformSupported {
    this.registry.onAuditAppended = _handleAuditAppended;
  }

  static final instance = McpServerController();
  final McpServerAuthService auth;
  final McpAuthorizationService authorization;
  final McpCapabilityRegistry registry;
  final McpNetworkService network;
  final bool? _platformSupportedOverride;
  final audit = McpAccessAuditService.instance;

  bool get platformSupportsServer =>
      _platformSupportedOverride ??
      (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux));

  McpServerState _state = const McpServerState();
  McpServerState get state => _state;
  Stream<McpServerState> get states => _states.stream;
  final _states = StreamController<McpServerState>.broadcast();
  StreamSubscription<void>? _lifecycle;
  McpHttpServerHost? _server;
  McpServerConfig _config = const McpServerConfig();
  int _generation = 0;
  Timer? _networkMonitor;

  McpServerConfig get config => _config;

  Future<McpServerConfig> loadConfig() async {
    final raw = await StorageService.getString(StorageKeys.mcpServerConfig);
    if (raw == null || raw.isEmpty) return _config = const McpServerConfig();
    try {
      _config = McpServerConfig.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      _config = const McpServerConfig();
    }
    return _config;
  }

  Future<void> saveConfig(McpServerConfig config) async {
    final normalized =
        config.accessScope == McpAccessScope.lan && !config.apiKeyEnabled
        ? config.copyWith(apiKeyEnabled: true)
        : config;
    final wasRunning = _state.isRunning;
    if (wasRunning) invalidateExecutionContext();
    _config = normalized;
    await StorageService.setString(
      StorageKeys.mcpServerConfig,
      jsonEncode(normalized.toJson()),
    );
    // A persisted disabled flag is authoritative.  Do not briefly restart a
    // listener while the user is turning it off; this also makes config
    // changes safe for callers that do not separately invoke stop().
    if (wasRunning) {
      if (normalized.enabled) {
        await restart();
      } else {
        await stop();
      }
    }
  }

  Future<void> setGrant(McpDataDomain domain, bool enabled) async {
    await authorization.setGrant(domain, enabled);
    if (_state.isRunning) await restart();
  }

  /// Invalidates every in-flight capability read before account, credential,
  /// cache, or privacy state is changed.
  void invalidateExecutionContext() {
    registry.executionContext.invalidate();
  }

  /// Runs a sensitive local-data mutation with the listener closed.
  ///
  /// Calls already executing are invalidated synchronously before shutdown;
  /// a previously running, still-enabled service resumes after the mutation.
  Future<T> runWithInvalidatedExecutionContext<T>(
    Future<T> Function() operation, {
    bool restartWhenComplete = true,
  }) async {
    final shouldRestart =
        restartWhenComplete && _state.isRunning && _config.enabled;
    invalidateExecutionContext();
    await stop();
    try {
      return await operation();
    } finally {
      if (shouldRestart && _config.enabled) await start();
    }
  }

  Future<void> start() async {
    if (_state.isRunning || _state.isBusy) return;
    if (!_config.enabled) return;
    if (!platformSupportsServer) {
      _publish(
        _state.copyWith(
          phase: McpServerPhase.failed,
          errorMessage: '当前平台不支持运行 MCP 服务。',
        ),
      );
      return;
    }
    if (!_config.canStart) {
      _publish(
        _state.copyWith(
          phase: McpServerPhase.failed,
          errorMessage: '配置无效：请检查端口、局域网风险确认和 API Key。',
        ),
      );
      return;
    }
    final generation = ++_generation;
    _publish(
      McpServerState(phase: McpServerPhase.starting, generation: generation),
    );
    try {
      final grants = await authorization.read();
      if (_config.apiKeyEnabled) {
        final keyStatus = await auth.status();
        if (!keyStatus.hasKey) throw StateError('请先生成 API Key');
      }
      final host = mcpBindAddress(_config.accessScope);
      final lanAddresses = _config.accessScope == McpAccessScope.lan
          ? await network.privateIpv4Addresses()
          : const <String>[];
      if (_config.accessScope == McpAccessScope.lan && lanAddresses.isEmpty) {
        throw StateError('未找到可用的局域网 IPv4 地址');
      }
      final allowedHosts = <String>{'127.0.0.1', 'localhost', ...lanAddresses};
      final server = McpHttpServerHost(
        host: host,
        port: _config.port,
        allowedHosts: allowedHosts,
        apiKeyEnabled: _config.apiKeyEnabled,
        auth: auth,
        audit: audit,
        serverFactory: (_) => registry.createServer(grants),
        onAuditAppended: _handleAuditAppended,
      );
      await server.start();
      if (generation != _generation) {
        await server.stop();
        return;
      }
      _server = server;
      _publish(
        McpServerState(
          phase: McpServerPhase.running,
          bindAddress: host,
          port: server.boundPort,
          endpoint:
              _config.accessScope == McpAccessScope.lan &&
                  lanAddresses.isNotEmpty
              ? 'http://${lanAddresses.first}:${server.boundPort}/mcp'
              : 'http://127.0.0.1:${server.boundPort}/mcp',
          generation: generation,
        ),
      );
      if (_config.accessScope == McpAccessScope.lan) {
        _startNetworkMonitor(lanAddresses);
      }
    } catch (error) {
      await _server?.stop();
      _server = null;
      _publish(
        _state.copyWith(
          phase: McpServerPhase.failed,
          errorMessage: _friendlyStartError(error),
          generation: generation,
        ),
      );
    }
  }

  Future<void> stop() async {
    if (_state.phase == McpServerPhase.stopped ||
        _state.phase == McpServerPhase.stopping) {
      return;
    }
    invalidateExecutionContext();
    ++_generation;
    _stopNetworkMonitor();
    _publish(_state.copyWith(phase: McpServerPhase.stopping));
    await _server?.stop();
    _server = null;
    _publish(McpServerState(generation: _generation));
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  Future<void> disposeServer() async {
    await stop();
    await _states.close();
    _lifecycle?.cancel();
    super.dispose();
  }

  void _startNetworkMonitor(List<String> initialAddresses) {
    _stopNetworkMonitor();
    var previous = List<String>.of(initialAddresses)..sort();
    _networkMonitor = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_state.isRunning || _config.accessScope != McpAccessScope.lan) {
        _stopNetworkMonitor();
        return;
      }
      try {
        final current = await network.privateIpv4Addresses();
        final sorted = List<String>.of(current)..sort();
        if (_sameAddresses(previous, sorted)) return;
        previous = sorted;
        if (sorted.isEmpty) {
          await stop();
          _publish(
            _state.copyWith(
              phase: McpServerPhase.failed,
              errorMessage: '局域网地址已变化，暂时无法提供局域网访问。',
            ),
          );
        } else {
          await restart();
        }
      } catch (_) {
        // A transient interface enumeration failure must not expose a stale
        // allowlist. Stop the listener and surface a recoverable state.
        await stop();
        _publish(
          _state.copyWith(
            phase: McpServerPhase.failed,
            errorMessage: '无法确认当前局域网地址，请检查网络后重试。',
          ),
        );
      }
    });
  }

  void _stopNetworkMonitor() {
    _networkMonitor?.cancel();
    _networkMonitor = null;
  }

  bool _sameAddresses(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) return false;
    }
    return true;
  }

  String _friendlyStartError(Object error) {
    if (error is SocketException) {
      final code = error.osError?.errorCode;
      if (code == 10048 || code == 10013 || code == 98 || code == 48) {
        return '端口不可用或已被占用，请更换端口。';
      }
      return '端口不可用、已被占用或缺少网络权限，请更换端口并检查系统网络权限。';
    }
    if (error is StateError) {
      final message = error.message;
      if (message == '请先生成 API Key' || message == '未找到可用的局域网 IPv4 地址') {
        return message;
      }
    }
    return 'MCP 服务启动失败，请检查端口、访问范围和系统权限。';
  }

  void _publish(McpServerState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
    notifyListeners();
  }

  void _handleAuditAppended() {
    _publish(_state.copyWith(lastAccessAt: DateTime.now()));
  }
}
