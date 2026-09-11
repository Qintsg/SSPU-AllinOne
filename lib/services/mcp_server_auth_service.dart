import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class McpApiKeyStatus {
  const McpApiKeyStatus({required this.hasKey, this.createdAt});
  final bool hasKey;
  final DateTime? createdAt;
}

class McpServerAuthService {
  McpServerAuthService._();
  static final instance = McpServerAuthService._();

  static const _secretKey = 'mcp_server_api_key';
  static const _createdAtKey = 'mcp_server_api_key_created_at';
  static const _storage = FlutterSecureStorage();

  Future<McpApiKeyStatus> status() async {
    final key = await _storage.read(key: _secretKey);
    final created = await _storage.read(key: _createdAtKey);
    return McpApiKeyStatus(
      hasKey: key != null && key.isNotEmpty,
      createdAt: DateTime.tryParse(created ?? ''),
    );
  }

  Future<String> generate() => _replace();
  Future<String> rotate() => _replace();

  Future<String> _replace() async {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final value = base64UrlEncode(bytes).replaceAll('=', '');
    await _storage.write(key: _secretKey, value: value);
    await _storage.write(
      key: _createdAtKey,
      value: DateTime.now().toUtc().toIso8601String(),
    );
    return value;
  }

  Future<void> disable() async {
    await _storage.delete(key: _secretKey);
    await _storage.delete(key: _createdAtKey);
  }

  Future<bool> verify(String candidate) async {
    if (candidate.isEmpty) return false;
    final expected = await _storage.read(key: _secretKey);
    if (expected == null || expected.isEmpty) return false;
    final left = sha256.convert(utf8.encode(candidate)).bytes;
    final right = sha256.convert(utf8.encode(expected)).bytes;
    var diff = left.length ^ right.length;
    for (var i = 0; i < left.length && i < right.length; i++) {
      diff |= left[i] ^ right[i];
    }
    return diff == 0;
  }
}
