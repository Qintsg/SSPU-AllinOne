import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mcp_dart/mcp_dart.dart';

import '../models/mcp_access_audit.dart';
import 'mcp_access_audit_service.dart';
import 'mcp_server_auth_service.dart';

/// Hardened HTTP edge for the MCP SDK server.
///
/// `mcp_dart` owns protocol negotiation and JSON-RPC handling on an ephemeral
/// loopback socket. This edge owns the user-visible socket and enforces limits
/// before forwarding a bounded request to the SDK. The backend requires a
/// random process-local header, so it cannot be used to bypass the edge.
class McpHttpServerHost {
  McpHttpServerHost({
    required this.host,
    required this.port,
    required this.allowedHosts,
    required this.apiKeyEnabled,
    required this.auth,
    required this.audit,
    required this.serverFactory,
    this.onAuditAppended,
  });

  static const maxRequestBytes = 256 * 1024;
  static const maxResponseBytes = 1024 * 1024;
  static const maxBurstRequests = 10;

  final String host;
  final int port;
  final Set<String> allowedHosts;
  final bool apiKeyEnabled;
  final McpServerAuthService auth;
  final McpAccessAuditService audit;
  final McpServer Function(String sessionId) serverFactory;
  final void Function()? onAuditAppended;

  final HttpClient _client = HttpClient();
  final Map<String, _RateBucket> _rateBuckets = {};
  HttpServer? _edge;
  StreamableMcpServer? _backend;
  late String _proxySecret;

  int get boundPort => _edge?.port ?? port;

  Future<void> start() async {
    if (_edge != null || _backend != null) {
      throw StateError('Server already started');
    }
    _proxySecret = _randomSecret();
    final backend = StreamableMcpServer(
      host: InternetAddress.loopbackIPv4.address,
      port: 0,
      path: '/mcp',
      protocol: McpProtocol.require2026,
      enableJsonResponse: true,
      strictProtocolVersionHeaderValidation: true,
      rejectBatchJsonRpcPayloads: true,
      allowedHosts: const {'127.0.0.1', 'localhost'},
      allowedOrigins: const {'https://invalid.invalid'},
      authenticationHandler: (request) {
        final supplied = request.headers.value('x-sspu-mcp-proxy') ?? '';
        return _constantEquals(supplied, _proxySecret)
            ? const StreamableMcpAuthenticationResult.allow()
            : const StreamableMcpAuthenticationResult.unauthorized();
      },
      serverFactory: serverFactory,
    );
    try {
      await backend.start();
      _backend = backend;
      final edge = await HttpServer.bind(host, port);
      _edge = edge;
      edge.listen(_handleRequest, onError: (_) {});
    } catch (_) {
      await backend.stop();
      _backend = null;
      rethrow;
    }
  }

  Future<void> stop() async {
    final edge = _edge;
    _edge = null;
    await edge?.close(force: true);
    final backend = _backend;
    _backend = null;
    await backend?.stop();
    _client.close(force: true);
    _rateBuckets.clear();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final stopwatch = Stopwatch()..start();
    final source =
        request.connectionInfo?.remoteAddress.address ?? 'unknown-client';
    try {
      if (request.uri.path != '/mcp') {
        await _respond(request, HttpStatus.notFound, 'Not Found');
        return;
      }
      if (request.method != 'POST') {
        request.response.headers.set(HttpHeaders.allowHeader, 'POST');
        await _respond(
          request,
          HttpStatus.methodNotAllowed,
          'Method Not Allowed',
        );
        return;
      }
      final length = request.contentLength;
      if (length > maxRequestBytes) {
        await _reject(
          request,
          source,
          'transport.body',
          'too_large',
          HttpStatus.requestEntityTooLarge,
          stopwatch,
        );
        return;
      }
      if (!_hostAllowed(request.headers.value(HttpHeaders.hostHeader))) {
        await _reject(
          request,
          source,
          'transport.host',
          'denied',
          HttpStatus.forbidden,
          stopwatch,
        );
        return;
      }
      final origin = request.headers.value('origin');
      if (origin != null && origin.trim().isNotEmpty) {
        await _reject(
          request,
          source,
          'transport.origin',
          'denied',
          HttpStatus.forbidden,
          stopwatch,
        );
        return;
      }
      if (apiKeyEnabled && !await _authenticate(request)) {
        request.response.headers.set(
          HttpHeaders.wwwAuthenticateHeader,
          'Bearer',
        );
        await _reject(
          request,
          source,
          'transport.auth',
          'denied',
          HttpStatus.unauthorized,
          stopwatch,
        );
        return;
      }
      if (!_allowRate(source)) {
        request.response.headers.set(HttpHeaders.retryAfterHeader, '1');
        await _reject(
          request,
          source,
          'transport.rate',
          'rate_limited',
          HttpStatus.tooManyRequests,
          stopwatch,
        );
        return;
      }
      final contentType = request.headers.contentType;
      if (contentType?.mimeType != ContentType.json.mimeType) {
        await _respond(
          request,
          HttpStatus.unsupportedMediaType,
          'Content-Type must be application/json',
        );
        return;
      }
      final body = await _readBounded(request, maxRequestBytes);
      if (body == null) {
        await _audit(
          source,
          'transport.body',
          false,
          'too_large',
          stopwatch.elapsedMilliseconds,
        );
        try {
          await _respond(
            request,
            HttpStatus.requestEntityTooLarge,
            'Request body is too large',
          );
        } catch (_) {}
        return;
      }
      await _forward(request, _injectSource(body, source));
    } catch (_) {
      try {
        await _respond(
          request,
          HttpStatus.internalServerError,
          'MCP transport error',
        );
      } catch (_) {}
    }
  }

  Future<bool> _authenticate(HttpRequest request) async {
    final header = request.headers.value(HttpHeaders.authorizationHeader) ?? '';
    if (!header.startsWith('Bearer ')) return false;
    return auth.verify(header.substring(7));
  }

  bool _hostAllowed(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return allowedHosts.contains(_normalizeHost(value));
  }

  String _normalizeHost(String value) {
    final lower = value.trim().toLowerCase();
    if (lower.startsWith('[')) {
      final end = lower.indexOf(']');
      return end > 1 ? lower.substring(1, end) : lower;
    }
    final first = lower.indexOf(':');
    final last = lower.lastIndexOf(':');
    return first >= 0 && first == last ? lower.substring(0, first) : lower;
  }

  bool _allowRate(String source) {
    final now = DateTime.now();
    final bucket = _rateBuckets.putIfAbsent(
      source,
      () => _RateBucket(maxBurstRequests.toDouble(), now),
    );
    final elapsed = now.difference(bucket.updatedAt).inMilliseconds / 1000;
    bucket.tokens = min(maxBurstRequests.toDouble(), bucket.tokens + elapsed);
    bucket.updatedAt = now;
    if (bucket.tokens < 1) return false;
    bucket.tokens -= 1;
    return true;
  }

  Future<Uint8List?> _readBounded(HttpRequest request, int limit) async {
    final bytes = BytesBuilder(copy: false);
    var size = 0;
    await for (final chunk in request) {
      size += chunk.length;
      if (size > limit) return null;
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Uint8List _injectSource(Uint8List body, String source) {
    try {
      final decoded = jsonDecode(utf8.decode(body));
      if (decoded is! Map<String, dynamic>) return body;
      final params = decoded['params'];
      if (params is! Map<String, dynamic>) return body;
      final rawMeta = params['_meta'];
      final meta = rawMeta is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawMeta)
          : <String, dynamic>{};
      meta['com.sspu/sourceAddress'] = source;
      params['_meta'] = meta;
      return Uint8List.fromList(utf8.encode(jsonEncode(decoded)));
    } catch (_) {
      return body;
    }
  }

  Future<void> _forward(HttpRequest request, Uint8List body) async {
    final backend = _backend;
    if (backend == null) {
      await _respond(request, HttpStatus.serviceUnavailable, 'Unavailable');
      return;
    }
    final upstream = await _client.postUrl(
      Uri.parse('http://127.0.0.1:${backend.boundPort}/mcp'),
    );
    for (final name in const [
      HttpHeaders.acceptHeader,
      HttpHeaders.contentTypeHeader,
      'mcp-protocol-version',
      'mcp-method',
      'mcp-name',
    ]) {
      final values = request.headers[name];
      if (values != null) upstream.headers.set(name, values);
    }
    upstream.headers.set('x-sspu-mcp-proxy', _proxySecret);
    upstream.add(body);
    final response = await upstream.close();
    final responseBody = await _readResponseBounded(response);
    if (responseBody == null) {
      await _respond(
        request,
        HttpStatus.badGateway,
        'MCP response is too large',
      );
      return;
    }
    request.response.statusCode = response.statusCode;
    for (final name in const [
      HttpHeaders.contentTypeHeader,
      HttpHeaders.cacheControlHeader,
      'mcp-session-id',
      'mcp-protocol-version',
    ]) {
      final values = response.headers[name];
      if (values != null) request.response.headers.set(name, values);
    }
    request.response.add(responseBody);
    await request.response.close();
  }

  Future<Uint8List?> _readResponseBounded(HttpClientResponse response) async {
    final bytes = BytesBuilder(copy: false);
    var size = 0;
    await for (final chunk in response) {
      size += chunk.length;
      if (size > maxResponseBytes) return null;
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Future<void> _reject(
    HttpRequest request,
    String source,
    String capability,
    String outcome,
    int status,
    Stopwatch stopwatch,
  ) async {
    await _audit(
      source,
      capability,
      false,
      outcome,
      stopwatch.elapsedMilliseconds,
    );
    await _respond(request, status, _fixedStatusMessage(status));
  }

  Future<void> _audit(
    String source,
    String capability,
    bool allowed,
    String outcome,
    int durationMs,
  ) {
    return audit
        .append(
          McpAccessAudit(
            occurredAt: DateTime.now().toUtc(),
            source: source,
            capability: capability,
            allowed: allowed,
            outcome: outcome,
            durationMs: durationMs,
          ),
        )
        .whenComplete(() => onAuditAppended?.call());
  }

  Future<void> _respond(HttpRequest request, int status, String message) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': message}));
    await request.response.close();
  }

  String _fixedStatusMessage(int status) => switch (status) {
    HttpStatus.unauthorized => 'Unauthorized',
    HttpStatus.forbidden => 'Forbidden',
    HttpStatus.requestEntityTooLarge => 'Request body is too large',
    HttpStatus.tooManyRequests => 'Too many requests',
    _ => 'Request rejected',
  };

  String _randomSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  bool _constantEquals(String left, String right) {
    final leftDigest = sha256.convert(utf8.encode(left)).bytes;
    final rightDigest = sha256.convert(utf8.encode(right)).bytes;
    var difference = leftDigest.length ^ rightDigest.length;
    for (var i = 0; i < leftDigest.length && i < rightDigest.length; i++) {
      difference |= leftDigest[i] ^ rightDigest[i];
    }
    return difference == 0;
  }
}

class _RateBucket {
  _RateBucket(this.tokens, this.updatedAt);
  double tokens;
  DateTime updatedAt;
}
