import 'dart:convert';

enum McpAccessScope { loopback, lan }

class McpServerConfig {
  const McpServerConfig({
    this.enabled = false,
    this.accessScope = McpAccessScope.loopback,
    this.port = 8765,
    this.apiKeyEnabled = true,
    this.lanRiskAcceptedAt,
  });

  final bool enabled;
  final McpAccessScope accessScope;
  final int port;
  final bool apiKeyEnabled;
  final DateTime? lanRiskAcceptedAt;

  bool get isValidPort => port >= 1024 && port <= 65535;
  bool get requiresApiKey => accessScope == McpAccessScope.lan;
  bool get canStart =>
      isValidPort &&
      (!requiresApiKey || apiKeyEnabled) &&
      (accessScope == McpAccessScope.loopback || lanRiskAcceptedAt != null);

  McpServerConfig copyWith({
    bool? enabled,
    McpAccessScope? accessScope,
    int? port,
    bool? apiKeyEnabled,
    DateTime? lanRiskAcceptedAt,
    bool clearLanRiskAcceptedAt = false,
  }) {
    return McpServerConfig(
      enabled: enabled ?? this.enabled,
      accessScope: accessScope ?? this.accessScope,
      port: port ?? this.port,
      apiKeyEnabled: apiKeyEnabled ?? this.apiKeyEnabled,
      lanRiskAcceptedAt: clearLanRiskAcceptedAt
          ? null
          : lanRiskAcceptedAt ?? this.lanRiskAcceptedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'accessScope': accessScope.name,
    'port': port,
    'apiKeyEnabled': apiKeyEnabled,
    'lanRiskAcceptedAt': lanRiskAcceptedAt?.toUtc().toIso8601String(),
  };

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    final scope = McpAccessScope.values.firstWhere(
      (item) => item.name == json['accessScope'],
      orElse: () => McpAccessScope.loopback,
    );
    final parsedPort = (json['port'] as num?)?.toInt() ?? 8765;
    final parsedRisk = DateTime.tryParse(
      json['lanRiskAcceptedAt'] as String? ?? '',
    );
    final config = McpServerConfig(
      enabled: json['enabled'] == true,
      accessScope: scope,
      port: parsedPort,
      apiKeyEnabled: json['apiKeyEnabled'] != false,
      lanRiskAcceptedAt: parsedRisk,
    );
    return scope == McpAccessScope.lan && !config.apiKeyEnabled
        ? config.copyWith(apiKeyEnabled: true)
        : config;
  }

  String encode() => jsonEncode(toJson());
}
