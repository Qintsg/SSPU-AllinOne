enum McpDataDomain {
  profile,
  grades,
  schedule,
  program,
  secondClassroom,
  exams,
  campusCard,
  messages,
  email,
}

class McpAuthorization {
  const McpAuthorization({this.grants = const {}, this.version = 0});

  final Map<McpDataDomain, bool> grants;
  final int version;

  bool isAllowed(McpDataDomain domain) => grants[domain] == true;

  McpAuthorization set(McpDataDomain domain, bool enabled) => McpAuthorization(
    grants: {...grants, domain: enabled},
    version: version + 1,
  );

  Map<String, dynamic> toJson() => {
    'version': version,
    'grants': {for (final entry in grants.entries) entry.key.name: entry.value},
  };

  factory McpAuthorization.fromJson(Map<String, dynamic> json) {
    final values = <McpDataDomain, bool>{};
    final raw = json['grants'];
    if (raw is Map) {
      for (final domain in McpDataDomain.values) {
        if (raw[domain.name] is bool) {
          values[domain] = raw[domain.name] as bool;
        }
      }
    }
    return McpAuthorization(
      grants: values,
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }
}
