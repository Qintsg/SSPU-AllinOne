class McpAccessAudit {
  const McpAccessAudit({
    required this.occurredAt,
    required this.source,
    required this.capability,
    required this.allowed,
    required this.outcome,
    this.errorCategory,
    required this.durationMs,
  });

  final DateTime occurredAt;
  final String source;
  final String capability;
  final bool allowed;
  final String outcome;
  final String? errorCategory;
  final int durationMs;

  Map<String, dynamic> toJson() => {
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'source': source,
    'capability': capability,
    'allowed': allowed,
    'outcome': outcome,
    'errorCategory': errorCategory,
    'durationMs': durationMs,
  };

  factory McpAccessAudit.fromJson(Map<String, dynamic> json) => McpAccessAudit(
    occurredAt:
        DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
        DateTime.now(),
    source: json['source'] as String? ?? 'unknown',
    capability: json['capability'] as String? ?? 'transport',
    allowed: json['allowed'] == true,
    outcome: json['outcome'] as String? ?? 'error',
    errorCategory: json['errorCategory'] as String?,
    durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
  );
}
