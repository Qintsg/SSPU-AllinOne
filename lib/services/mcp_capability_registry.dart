import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mcp_dart/mcp_dart.dart';

import '../models/mcp_access_audit.dart';
import '../models/mcp_authorization.dart';
import 'mcp_access_audit_service.dart';
import 'mcp_authorization_service.dart';
import 'mcp_execution_context_service.dart';
import 'mcp_snapshot_adapters.dart';

class McpCapabilityRegistry {
  McpCapabilityRegistry({
    McpSnapshotAdapters? adapters,
    McpAccessAuditService? audit,
    McpAuthorizationService? authorization,
    McpExecutionContextService? executionContext,
    this.maxConcurrentCalls = defaultMaxConcurrentCalls,
    this.toolTimeout = defaultToolTimeout,
    this.maxResponseBytes = defaultMaxResponseBytes,
  }) : adapters = adapters ?? McpSnapshotAdapters(),
       audit = audit ?? McpAccessAuditService.instance,
       authorization = authorization ?? McpAuthorizationService.instance,
       executionContext =
           executionContext ?? McpExecutionContextService.instance,
       _cursorKey = Uint8List.fromList(
         List<int>.generate(32, (_) => Random.secure().nextInt(256)),
       );

  final McpSnapshotAdapters adapters;
  final McpAccessAuditService audit;
  final McpAuthorizationService authorization;
  final McpExecutionContextService executionContext;
  final int maxConcurrentCalls;
  final Duration toolTimeout;
  final int maxResponseBytes;
  final Uint8List _cursorKey;
  void Function()? onAuditAppended;
  int _activeCalls = 0;

  static const defaultMaxConcurrentCalls = 4;
  static const defaultToolTimeout = Duration(seconds: 5);
  static const defaultMaxResponseBytes = 1024 * 1024;

  static const _annotations = ToolAnnotations(
    readOnlyHint: true,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  );

  McpServer createServer(McpAuthorization authorization) {
    final server = McpServer(
      const Implementation(name: 'sspu-allinone', version: '0.4.0'),
      options: const McpServerOptions(protocol: McpProtocol.require2026),
    );
    void register(
      String name,
      McpDataDomain domain,
      String description,
      Future<McpSnapshotEnvelope> Function(Map<String, dynamic> args) handler, {
      JsonObject? inputSchema,
    }) {
      final tool = server.registerTool(
        name,
        description: description,
        inputSchema: inputSchema ?? _pagedSchema(),
        annotations: _annotations,
        callback: (args, extra) async {
          final stopwatch = Stopwatch()..start();
          final contextGeneration = executionContext.capture();
          final before = await this.authorization.read();
          if (!before.isAllowed(domain)) {
            await _audit(
              name,
              false,
              'denied',
              stopwatch.elapsedMilliseconds,
              source: _source(extra),
            );
            return const CallToolResult(
              content: [TextContent(text: '该数据范围尚未获得授权。')],
              isError: true,
            );
          }
          if (_activeCalls >= maxConcurrentCalls) {
            await _audit(
              name,
              true,
              'rate_limited',
              stopwatch.elapsedMilliseconds,
              source: _source(extra),
            );
            return const CallToolResult(
              content: [TextContent(text: '并发请求过多，请稍后重试。')],
              isError: true,
            );
          }
          _activeCalls++;
          try {
            _validateFilters(name, args);
            final envelope = await handler(args).timeout(toolTimeout);
            final after = await this.authorization.read();
            final dataContextChanged = !executionContext.isCurrent(
              contextGeneration,
            );
            final authorizationChanged =
                after.version != before.version || !after.isAllowed(domain);
            if (dataContextChanged || authorizationChanged) {
              await _audit(
                name,
                false,
                'context_changed',
                stopwatch.elapsedMilliseconds,
                source: _source(extra),
              );
              return CallToolResult(
                content: [
                  TextContent(
                    text: dataContextChanged
                        ? '数据上下文已变化，请重新发起请求。'
                        : '授权上下文已变化，请重新发起请求。',
                  ),
                ],
                isError: true,
              );
            }
            final result = _paginate(envelope, args, name, before.version);
            if (utf8.encode(jsonEncode(result.toJson())).length >
                maxResponseBytes) {
              await _audit(
                name,
                true,
                'result_too_large',
                stopwatch.elapsedMilliseconds,
                source: _source(extra),
              );
              return const CallToolResult(
                content: [TextContent(text: '结果过大，请缩小查询范围或分页读取。')],
                isError: true,
              );
            }
            await _audit(
              name,
              true,
              result.status,
              stopwatch.elapsedMilliseconds,
              source: _source(extra),
            );
            return CallToolResult(
              content: [TextContent(text: '已返回 ${result.status} 本地快照。')],
              structuredContent: result.toJson(),
            );
          } on TimeoutException {
            await _audit(
              name,
              true,
              'timeout',
              stopwatch.elapsedMilliseconds,
              source: _source(extra),
            );
            return const CallToolResult(
              content: [TextContent(text: '读取本地快照超时，请稍后重试。')],
              isError: true,
            );
          } on FormatException catch (error) {
            final isCursor = error.message == 'invalid cursor';
            await _audit(
              name,
              false,
              isCursor ? 'invalid_cursor' : 'invalid_params',
              stopwatch.elapsedMilliseconds,
              source: _source(extra),
            );
            return CallToolResult(
              content: [
                TextContent(
                  text: isCursor ? '分页游标无效，请从第一页重新开始。' : '查询参数无效，请检查日期范围和分页参数。',
                ),
              ],
              isError: true,
            );
          } catch (_) {
            await _audit(
              name,
              true,
              'error',
              stopwatch.elapsedMilliseconds,
              source: _source(extra),
            );
            return const CallToolResult(
              content: [TextContent(text: '读取本地快照失败，请检查查询参数。')],
              isError: true,
            );
          } finally {
            _activeCalls--;
          }
        },
      );
      if (!authorization.isAllowed(domain)) tool.disable();
    }

    register(
      'get_current_profile',
      McpDataDomain.profile,
      '读取当前用户的最小学籍资料摘要。',
      (_) => adapters.profile(),
      inputSchema: _emptySchema(),
    );
    register(
      'list_schedule',
      McpDataDomain.schedule,
      '读取本地课表快照。',
      (_) => adapters.schedule(),
    );
    register(
      'list_grades',
      McpDataDomain.grades,
      '读取本地成绩快照。',
      (_) => adapters.grades(),
    );
    register(
      'list_exams',
      McpDataDomain.exams,
      '读取本地考试安排快照。',
      (_) => adapters.exams(),
    );
    register(
      'get_program_progress',
      McpDataDomain.program,
      '读取培养计划完成进度摘要。',
      (_) => adapters.program(),
      inputSchema: _emptySchema(),
    );
    register(
      'get_second_classroom_credits',
      McpDataDomain.secondClassroom,
      '读取第二课堂学分快照。',
      (_) => adapters.secondClassroom(),
    );
    register(
      'get_campus_card_summary',
      McpDataDomain.campusCard,
      '读取校园卡余额和状态摘要。',
      (_) => adapters.campusCard(),
      inputSchema: _emptySchema(),
    );
    register(
      'list_campus_card_transactions',
      McpDataDomain.campusCard,
      '读取本地校园卡交易快照。',
      adapters.campusCardTransactions,
      inputSchema: _pagedSchema({
        'from': JsonSchema.string(format: 'date'),
        'to': JsonSchema.string(format: 'date'),
        'direction': JsonSchema.string(
          enumValues: const ['debit', 'credit', 'all'],
          defaultValue: 'all',
        ),
      }),
    );
    register(
      'search_messages',
      McpDataDomain.messages,
      '搜索本地已有的校园消息标题与摘要。',
      adapters.messages,
      inputSchema: _pagedSchema({
        'query': JsonSchema.string(minLength: 1, maxLength: 100),
        'from': JsonSchema.string(format: 'date'),
        'to': JsonSchema.string(format: 'date'),
        'source': JsonSchema.string(minLength: 1, maxLength: 100),
      }),
    );
    register(
      'search_email',
      McpDataDomain.email,
      '搜索本地已有的学校邮箱列表快照，不返回正文或附件内容。',
      adapters.email,
      inputSchema: _pagedSchema({
        'query': JsonSchema.string(minLength: 1, maxLength: 100),
        'from': JsonSchema.string(format: 'date'),
        'to': JsonSchema.string(format: 'date'),
        'folder': JsonSchema.string(
          enumValues: const ['inbox'],
          defaultValue: 'inbox',
        ),
      }),
    );
    return server;
  }

  JsonObject _emptySchema() =>
      JsonSchema.object(properties: const {}, additionalProperties: false);

  JsonObject _pagedSchema([Map<String, JsonSchema> extra = const {}]) =>
      JsonSchema.object(
        properties: {
          'limit': JsonSchema.integer(minimum: 1, maximum: 100),
          'cursor': JsonSchema.string(maxLength: 128),
          ...extra,
        },
        additionalProperties: false,
      );

  McpSnapshotEnvelope _paginate(
    McpSnapshotEnvelope envelope,
    Map<String, dynamic> args,
    String capability,
    int authorizationVersion,
  ) {
    final items = envelope.data?['items'];
    if (items is! List) return envelope;
    final limit = ((args['limit'] as num?)?.toInt() ?? 25).clamp(1, 100);
    var offset = 0;
    final cursor = args['cursor'];
    if (cursor is String && cursor.isNotEmpty) {
      offset = _decodeCursor(
        cursor,
        capability,
        _filterFingerprint(args),
        authorizationVersion,
      );
    }
    if (offset < 0 || offset > items.length) {
      throw const FormatException('invalid cursor');
    }
    final end = (offset + limit).clamp(0, items.length);
    final nextCursor = end < items.length
        ? _encodeCursor(
            end,
            capability,
            _filterFingerprint(args),
            authorizationVersion,
          )
        : null;
    return McpSnapshotEnvelope(
      status: envelope.status,
      snapshotAt: envelope.snapshotAt,
      data: {...?envelope.data, 'items': items.sublist(offset, end)},
      page: {
        'limit': limit,
        'hasMore': nextCursor != null,
        'nextCursor': nextCursor,
      },
    );
  }

  void _validateFilters(String capability, Map<String, dynamic> args) {
    final from = _parseDate(args['from']);
    final to = _parseDate(args['to']);
    if (from != null && to != null) {
      if (to.isBefore(from)) throw const FormatException('invalid range');
      final maxDays = switch (capability) {
        'list_campus_card_transactions' => 90,
        'search_messages' || 'search_email' => 365,
        _ => 180,
      };
      if (to.difference(from).inDays > maxDays) {
        throw const FormatException('range too large');
      }
    }
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('invalid date');
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw const FormatException('invalid date');
    return parsed;
  }

  String _filterFingerprint(Map<String, dynamic> args) {
    final keys =
        args.keys.where((key) => key != 'cursor' && key != 'limit').toList()
          ..sort();
    final canonical = <String, dynamic>{for (final key in keys) key: args[key]};
    return base64UrlEncode(
      sha256.convert(utf8.encode(jsonEncode(canonical))).bytes.take(9).toList(),
    ).replaceAll('=', '');
  }

  String _encodeCursor(
    int offset,
    String capability,
    String fingerprint,
    int authorizationVersion,
  ) {
    final payload = base64UrlEncode(
      utf8.encode(
        jsonEncode({
          'o': offset,
          't': capability,
          'f': fingerprint,
          'v': authorizationVersion,
        }),
      ),
    ).replaceAll('=', '');
    final signature = base64UrlEncode(
      Hmac(
        sha256,
        _cursorKey,
      ).convert(utf8.encode(payload)).bytes.take(16).toList(),
    ).replaceAll('=', '');
    return '$payload.$signature';
  }

  int _decodeCursor(
    String cursor,
    String capability,
    String fingerprint,
    int authorizationVersion,
  ) {
    try {
      final parts = cursor.split('.');
      if (parts.length != 2) throw const FormatException('invalid cursor');
      final expected = Hmac(
        sha256,
        _cursorKey,
      ).convert(utf8.encode(parts[0])).bytes.take(16).toList();
      final actual = base64Url.decode(base64Url.normalize(parts[1]));
      var difference = expected.length ^ actual.length;
      for (var i = 0; i < expected.length && i < actual.length; i++) {
        difference |= expected[i] ^ actual[i];
      }
      if (difference != 0) throw const FormatException('invalid cursor');
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
              )
              as Map<String, dynamic>;
      if (payload['t'] != capability ||
          payload['f'] != fingerprint ||
          payload['v'] != authorizationVersion) {
        throw const FormatException('invalid cursor');
      }
      final offset = payload['o'];
      if (offset is! int) throw const FormatException('invalid cursor');
      return offset;
    } catch (_) {
      throw const FormatException('invalid cursor');
    }
  }

  String _source(RequestHandlerExtra extra) {
    final injected = extra.meta?['com.sspu/sourceAddress'];
    if (injected is String && injected.isNotEmpty) return injected;
    final requestInfo = extra.requestInfo?.data;
    final address = requestInfo?['remoteAddress'];
    if (address is String && address.isNotEmpty) return address;
    return extra.clientInfo?.name ?? 'mcp-client';
  }

  Future<void> _audit(
    String capability,
    bool allowed,
    String outcome,
    int durationMs, {
    required String source,
  }) {
    return audit
        .append(
          McpAccessAudit(
            occurredAt: DateTime.now(),
            source: source,
            capability: capability,
            allowed: allowed,
            outcome: outcome,
            durationMs: durationMs,
          ),
        )
        .whenComplete(() => onAuditAppended?.call());
  }
}
