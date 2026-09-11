import 'dart:async';

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/mcp_authorization.dart';
import '../models/mcp_access_audit.dart';
import '../models/mcp_server_config.dart';
import '../models/mcp_server_state.dart';
import '../services/mcp_server_auth_service.dart';
import '../services/mcp_server_controller.dart';
import '../widgets/settings_widgets.dart';

class AiServicesPage extends StatefulWidget {
  const AiServicesPage({super.key, this.controller});
  final McpServerController? controller;

  @override
  State<AiServicesPage> createState() => _AiServicesPageState();
}

class _AiServicesPageState extends State<AiServicesPage> {
  late final McpServerController _controller;
  late final TextEditingController _portController;
  McpServerConfig _config = const McpServerConfig();
  McpAuthorization _authorization = const McpAuthorization();
  McpApiKeyStatus _keyStatus = const McpApiKeyStatus(hasKey: false);
  List<McpAccessAudit> _audits = const [];
  String? _newKey;
  bool _loading = true;
  DateTime? _observedLastAccessAt;

  bool get _supportsServer => _controller.platformSupportsServer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? McpServerController.instance;
    _controller.addListener(_handleControllerChanged);
    _portController = TextEditingController();
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _portController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final lastAccessAt = _controller.state.lastAccessAt;
    if (lastAccessAt == null || lastAccessAt == _observedLastAccessAt) return;
    _observedLastAccessAt = lastAccessAt;
    unawaited(_refreshAudits());
  }

  Future<void> _refreshAudits() async {
    final values = await _controller.audit.read();
    if (mounted) setState(() => _audits = values);
  }

  Future<void> _load() async {
    final config = await _controller.loadConfig();
    final auth = await _controller.authorization.read();
    final audits = await _controller.audit.read();
    McpApiKeyStatus key;
    try {
      key = await _controller.auth.status().timeout(
        const Duration(milliseconds: 500),
      );
    } catch (_) {
      key = const McpApiKeyStatus(hasKey: false);
    }
    if (!mounted) return;
    setState(() {
      _config = config;
      _portController.text = '${config.port}';
      _authorization = auth;
      _keyStatus = key;
      _audits = audits;
      _loading = false;
    });
  }

  Future<void> _saveAndStart({bool? enabled}) async {
    final port = int.tryParse(_portController.text.trim()) ?? _config.port;
    final next = _config.copyWith(enabled: enabled, port: port);
    await _controller.saveConfig(next);
    if (enabled == true) {
      await _controller.start();
    } else if (enabled == false) {
      await _controller.stop();
    }
    if (mounted) setState(() => _config = _controller.config);
  }

  Future<void> _generateKey({bool rotate = false}) async {
    final value = rotate
        ? await _controller.auth.rotate()
        : await _controller.auth.generate();
    if (!mounted) return;
    setState(() {
      _newKey = value;
      _keyStatus = McpApiKeyStatus(hasKey: true, createdAt: DateTime.now());
    });
    if (_controller.state.isRunning) await _controller.restart();
  }

  Future<void> _copyKey() async {
    final key = _newKey;
    if (key == null) return;
    await Clipboard.setData(ClipboardData(text: key));
    if (mounted) showYhFeedback(context, message: 'API Key 已复制；关闭页面后将不再显示原文。');
  }

  Future<void> _copyEndpoint() async {
    final endpoint = _controller.state.endpoint;
    if (endpoint == null) return;
    await Clipboard.setData(ClipboardData(text: endpoint));
    if (mounted) showYhFeedback(context, message: 'MCP 连接地址已复制。');
  }

  Future<void> _setScope(McpAccessScope scope) async {
    if (scope == McpAccessScope.lan) {
      final confirmed = await YhDialog.confirm(
        context,
        title: '允许局域网访问？',
        message: '服务会对同一局域网开放。HTTP 流量和 API Key 不加密，只应在可信网络使用。',
        confirmText: '确认并继续',
      );
      if (confirmed != true) return;
    }
    final next = _config.copyWith(
      accessScope: scope,
      apiKeyEnabled: scope == McpAccessScope.lan ? true : _config.apiKeyEnabled,
      lanRiskAcceptedAt: scope == McpAccessScope.lan ? DateTime.now() : null,
      clearLanRiskAcceptedAt: scope == McpAccessScope.loopback,
    );
    await _controller.saveConfig(next);
    if (mounted) setState(() => _config = next);
  }

  Future<void> _setApiKeyEnabled(bool enabled) async {
    if (!enabled && _config.accessScope == McpAccessScope.lan) return;
    if (!enabled) {
      final confirmed = await YhDialog.confirm(
        context,
        title: '关闭 API Key 认证？',
        message: '关闭后，同一设备上的其它进程可能直接读取已授权数据。仅建议在你完全信任的本机开发场景使用。',
        confirmText: '关闭认证',
      );
      if (confirmed != true) return;
    }
    if (enabled && !_keyStatus.hasKey) await _generateKey();
    final next = _config.copyWith(apiKeyEnabled: enabled);
    await _controller.saveConfig(next);
    if (mounted) setState(() => _config = next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: YhProgress(showPercent: false));
    final theme = context.yhTheme;
    return YhPageScaffold(
      appBar: const YhAppBar(title: 'AI 服务', eyebrow: '个人数据连接中心'),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => ListView(
          padding: EdgeInsets.all(theme.spacing.l),
          children: [
            _buildHero(context),
            SizedBox(height: theme.spacing.l),
            _buildServerCard(context),
            SizedBox(height: theme.spacing.l),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >=
                    theme.breakpoint.expanded - theme.spacing.l * 2;
                if (!wide) {
                  return Column(
                    key: const Key('ai-services-access-stack'),
                    children: [
                      _buildAuthorizationCard(context),
                      SizedBox(height: theme.spacing.l),
                      _buildAuditCard(context),
                    ],
                  );
                }
                return SizedBox(
                  height: theme.control.regular * 12 + theme.spacing.s,
                  child: Row(
                    key: const Key('ai-services-access-columns'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 13,
                        child: _buildAuthorizationCard(context),
                      ),
                      SizedBox(width: theme.spacing.l),
                      Expanded(flex: 7, child: _buildAuditCard(context)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      elevated: true,
      padding: EdgeInsets.all(theme.spacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.color.brandStrong,
              borderRadius: BorderRadius.circular(theme.radius.l),
            ),
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.m),
              child: Icon(YhIcons.connect, color: theme.color.onBrand),
            ),
          ),
          SizedBox(width: theme.spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('让 Agent 读懂你的校园生活', style: theme.typography.h2),
                SizedBox(height: theme.spacing.xs),
                Text(
                  '通过标准 MCP 连接，把你明确授权的本地快照交给其它 AI 应用。数据默认不出设备，也不会因为调用而自动联网。',
                  style: theme.typography.body.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(BuildContext context) {
    final theme = context.yhTheme;
    final state = _controller.state;
    final running = state.isRunning;
    final status = switch (state.phase) {
      McpServerPhase.running => '运行中',
      McpServerPhase.starting => '启动中',
      McpServerPhase.stopping => '停止中',
      McpServerPhase.failed => '启动失败',
      McpServerPhase.stopped => '未开启',
    };
    return YhCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('MCP 服务', style: theme.typography.h3)),
              Text(
                _supportsServer ? status : '当前平台不支持',
                style: theme.typography.body.copyWith(
                  color: running ? theme.color.success : theme.color.muted,
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            _supportsServer
                ? '标准 Streamable HTTP · 仅桌面端可用'
                : '当前平台不支持在设备上运行 MCP 服务；请使用 Windows、macOS 或 Linux 桌面版。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.globe,
            title: const Text('访问范围'),
            subtitle: Text(
              _config.accessScope == McpAccessScope.lan
                  ? '局域网（0.0.0.0）'
                  : '仅本机（127.0.0.1）',
            ),
            trailing: Wrap(
              spacing: theme.spacing.xs,
              children: [
                YhButton(
                  label: '仅本机',
                  variant: _config.accessScope == McpAccessScope.loopback
                      ? YhButtonVariant.primary
                      : YhButtonVariant.secondary,
                  onTap: _supportsServer
                      ? () => _setScope(McpAccessScope.loopback)
                      : null,
                ),
                YhButton(
                  label: '局域网',
                  variant: _config.accessScope == McpAccessScope.lan
                      ? YhButtonVariant.primary
                      : YhButtonVariant.secondary,
                  onTap: _supportsServer
                      ? () => _setScope(McpAccessScope.lan)
                      : null,
                ),
              ],
            ),
            stackTrailing: true,
          ),
          SizedBox(height: theme.spacing.s),
          buildResponsiveSettingsRow(
            context: context,
            icon: YhIcons.lock,
            title: const Text('API Key 认证'),
            subtitle: Text(
              _config.accessScope == McpAccessScope.lan
                  ? '局域网模式强制开启'
                  : (_config.apiKeyEnabled
                        ? '请求需要 Bearer Key'
                        : '仅本机免认证，请确认同设备风险'),
              style: theme.typography.small.copyWith(color: theme.color.muted),
            ),
            trailing: YhSwitch(
              value: _config.apiKeyEnabled,
              disabled:
                  !_supportsServer || _config.accessScope == McpAccessScope.lan,
              semanticLabel: 'API Key 认证',
              onChanged: _setApiKeyEnabled,
            ),
            stackTrailing: false,
          ),
          SizedBox(height: theme.spacing.s),
          Row(
            key: const Key('mcp-port-action-row'),
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: YhTextField(
                  label: '端口',
                  controller: _portController,
                  enabled: _supportsServer,
                  keyboardType: TextInputType.number,
                  helper: '1024–65535；修改后需要重新启动服务',
                ),
              ),
              SizedBox(width: theme.spacing.s),
              YhButton(
                label: running ? '停止服务' : '开启服务',
                leadingIcon: running ? YhIcons.power : YhIcons.connect,
                variant: running
                    ? YhButtonVariant.danger
                    : YhButtonVariant.primary,
                onTap: !_supportsServer || state.isBusy
                    ? null
                    : () => _saveAndStart(enabled: !running),
              ),
            ],
          ),
          if (state.endpoint != null) ...[
            SizedBox(height: theme.spacing.s),
            Wrap(
              spacing: theme.spacing.s,
              runSpacing: theme.spacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('连接地址：${state.endpoint}', style: theme.typography.small),
                YhButton(
                  label: '复制地址',
                  leadingIcon: YhIcons.save,
                  variant: YhButtonVariant.text,
                  onTap: _copyEndpoint,
                ),
              ],
            ),
          ],
          if (state.errorMessage != null) ...[
            SizedBox(height: theme.spacing.s),
            Text(
              state.errorMessage!,
              style: theme.typography.small.copyWith(color: theme.color.danger),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthorizationCard(BuildContext context) {
    final theme = context.yhTheme;
    final labels = <McpDataDomain, String>{
      McpDataDomain.profile: '个人信息',
      McpDataDomain.grades: '成绩',
      McpDataDomain.schedule: '课表',
      McpDataDomain.program: '培养计划',
      McpDataDomain.secondClassroom: '二课学分',
      McpDataDomain.exams: '考试安排',
      McpDataDomain.campusCard: '校园卡',
      McpDataDomain.messages: '校园消息',
      McpDataDomain.email: '学校邮箱',
    };
    return YhCard(
      key: const Key('mcp-authorization-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('授权外部应用访问', style: theme.typography.h3),
          SizedBox(height: theme.spacing.xs),
          Text(
            '默认全部关闭。只会读取本地已有快照，撤销后立即生效。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.m),
          for (final entry in labels.entries) ...[
            buildResponsiveSettingsRow(
              context: context,
              icon: YhIcons.database,
              title: Text(entry.value),
              subtitle: Text(
                entry.key == McpDataDomain.email ? '敏感文本，默认不返回完整正文' : '只读工具',
                style: theme.typography.small.copyWith(
                  color: theme.color.muted,
                ),
              ),
              trailing: YhSwitch(
                value: _authorization.isAllowed(entry.key),
                disabled: !_supportsServer,
                semanticLabel: '授权${entry.value}',
                onChanged: (value) async {
                  await _controller.setGrant(entry.key, value);
                  final next = await _controller.authorization.read();
                  if (mounted) setState(() => _authorization = next);
                },
              ),
              stackTrailing: false,
            ),
            SizedBox(height: theme.spacing.xs),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditCard(BuildContext context) {
    final theme = context.yhTheme;
    return YhCard(
      key: const Key('mcp-api-audit-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('API Key 与访问记录', style: theme.typography.h3),
          SizedBox(height: theme.spacing.s),
          Text(
            _keyStatus.hasKey
                ? 'API Key 已启用。原文只在生成或轮换后显示一次。'
                : 'API Key 尚未生成；局域网模式无法启动。',
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          if (_newKey != null) ...[
            SizedBox(height: theme.spacing.s),
            Text('本次 API Key', style: theme.typography.small),
            SizedBox(height: theme.spacing.xs),
            YhSelectableText(
              _newKey!,
              semanticLabel: '本次 API Key，仅显示一次',
              style: theme.typography.small,
            ),
          ],
          SizedBox(height: theme.spacing.m),
          Text(
            '最近访问',
            style: theme.typography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: theme.spacing.xs),
          if (_audits.isEmpty)
            Text(
              '暂无访问记录',
              style: theme.typography.small.copyWith(color: theme.color.muted),
            )
          else
            for (final entry in _audits.reversed.take(5))
              Padding(
                padding: EdgeInsets.only(bottom: theme.spacing.xs),
                child: Text(
                  '${entry.capability} · ${entry.outcome} · ${entry.occurredAt.toLocal()}',
                  style: theme.typography.small,
                ),
              ),
          SizedBox(height: theme.spacing.m),
          Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            children: [
              YhButton(
                label: _keyStatus.hasKey ? '轮换 Key' : '生成 Key',
                leadingIcon: YhIcons.lock,
                variant: YhButtonVariant.secondary,
                onTap: () => _generateKey(rotate: _keyStatus.hasKey),
              ),
              if (_newKey != null)
                YhButton(
                  label: '复制本次 Key',
                  leadingIcon: YhIcons.save,
                  onTap: _copyKey,
                ),
              YhButton(
                label: '清除访问记录',
                leadingIcon: YhIcons.clean,
                variant: YhButtonVariant.text,
                onTap: () async {
                  await _controller.audit.clear();
                  if (mounted) setState(() => _audits = const []);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
