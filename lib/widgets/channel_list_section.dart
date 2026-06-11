/*
 * 渠道列表组件 — 分区级渠道状态与刷新配置入口
 * @Project : SSPU-AllinOne
 * @File : channel_list_section.dart
 * @Author : Qintsg
 * @Date : 2026-04-22
 */

import '../design/fluent_ui.dart';

import '../models/channel_config.dart';
import '../models/message_item.dart';
import '../services/auto_refresh_service.dart';
import '../services/message_state_service.dart';
import '../theme/app_spacing.dart';
import 'app_feedback.dart';
import 'channel_list_panels.dart';
import 'responsive_layout.dart';

/// 渠道列表组件。
/// 负责加载分区级状态，并将渠道卡片与刷新面板组合到同一页。
class ChannelListSection extends StatefulWidget {
  /// 分组标题。
  final String title;

  /// 分组内的渠道配置列表。
  final List<ChannelConfig> channels;

  const ChannelListSection({
    super.key,
    required this.title,
    required this.channels,
  });

  @override
  State<ChannelListSection> createState() => _ChannelListSectionState();
}

class _ChannelListSectionState extends State<ChannelListSection> {
  final MessageStateService _messageState = MessageStateService.instance;
  final AutoRefreshService _autoRefresh = AutoRefreshService.instance;

  final Map<String, bool> _enabledMap = {};
  final Map<String, bool> _autoRefreshEnabledMap = {};
  final Map<String, int> _intervalMap = {};
  final Map<String, int> _manualCountMap = {};
  final Map<String, int> _autoCountMap = {};
  final Map<String, bool> _categoryEnabledMap = {};

  bool _groupAutoRefreshEnabled = false;
  int _groupInterval = 60;
  int _groupManualCount = 20;
  int _groupAutoCount = 20;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChannelStates();
  }

  /// 加载当前分区所有渠道状态。
  Future<void> _loadChannelStates() async {
    for (final channel in widget.channels) {
      _enabledMap[channel.id] = await _messageState.isChannelEnabled(
        channel.id,
        defaultValue: channel.defaultEnabled,
      );
      _autoRefreshEnabledMap[channel.id] = await _messageState
          .isChannelAutoRefreshEnabled(channel.id);
      _intervalMap[channel.id] = await _messageState.getChannelDisplayInterval(
        channel.id,
        defaultValue: channel.defaultInterval,
      );
      _manualCountMap[channel.id] = await _messageState
          .getChannelManualFetchCount(channel.id);
      _autoCountMap[channel.id] = await _messageState.getChannelAutoFetchCount(
        channel.id,
      );
    }

    _syncGroupRefreshState();

    for (final channel in widget.channels) {
      final subcategories = channelSubcategories[channel.id];
      if (subcategories == null) continue;
      for (final subcategory in subcategories) {
        _categoryEnabledMap[subcategory.category.name] = await _messageState
            .isCategoryEnabled(subcategory.category.name);
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  /// 同步分区级刷新设置的展示状态。
  void _syncGroupRefreshState() {
    ChannelConfig? sourceChannel;
    for (final channel in widget.channels) {
      if (!channel.implemented) continue;
      sourceChannel ??= channel;
      if ((_autoRefreshEnabledMap[channel.id] ?? false) &&
          (_intervalMap[channel.id] ?? 0) > 0) {
        sourceChannel = channel;
        break;
      }
    }

    if (sourceChannel == null) return;
    _groupAutoRefreshEnabled = widget.channels.any(
      (channel) =>
          channel.implemented && (_autoRefreshEnabledMap[channel.id] ?? false),
    );
    _groupInterval =
        _intervalMap[sourceChannel.id] ?? sourceChannel.defaultInterval;
    _groupManualCount = _manualCountMap[sourceChannel.id] ?? 20;
    _groupAutoCount = _autoCountMap[sourceChannel.id] ?? 20;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: FluentProgressRing());
    }

    final enabledCount = _enabledMap.values.where((enabled) => enabled).length;
    final autoEnabledCount = widget.channels
        .where(
          (channel) =>
              (_enabledMap[channel.id] ?? false) &&
              (_autoRefreshEnabledMap[channel.id] ?? false),
        )
        .length;
    final implementedChannels = widget.channels
        .where((channel) => channel.implemented)
        .toList(growable: false);
    final hasEnabledImplementedChannel = implementedChannels.any(
      (channel) => _enabledMap[channel.id] ?? false,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.appMetrics.contentMaxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChannelSectionOverview(
              title: widget.title,
              totalCount: widget.channels.length,
              implementedCount: implementedChannels.length,
              enabledCount: enabledCount,
              autoEnabledCount: autoEnabledCount,
              onEnableAll: () => _setAllChannelsEnabled(true),
              onDisableAll: () => _setAllChannelsEnabled(false),
            ),
            const SizedBox(height: AppSpacing.md),
            ChannelGroupRefreshPanel(
              enabled: hasEnabledImplementedChannel,
              hasImplementedChannel: implementedChannels.isNotEmpty,
              groupAutoRefreshEnabled: _groupAutoRefreshEnabled,
              groupInterval: _groupInterval,
              groupManualCount: _groupManualCount,
              groupAutoCount: _groupAutoCount,
              onGroupManualCountChanged: (value) =>
                  _onGroupManualCountChanged(value),
              onGroupAutoRefreshToggled: (value) =>
                  _onGroupAutoRefreshToggled(value),
              onGroupIntervalChanged: (value) => _onGroupIntervalChanged(value),
              onGroupAutoCountChanged: (value) =>
                  _onGroupAutoCountChanged(value),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final useTwoColumns = constraints.maxWidth >= 1040;
                final itemWidth = useTwoColumns
                    ? (constraints.maxWidth - AppSpacing.md) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: widget.channels.map((channel) {
                    return SizedBox(
                      width: itemWidth,
                      child: ChannelListItemCard(
                        channel: channel,
                        enabled: _enabledMap[channel.id] ?? false,
                        onToggled: (value) => _onChannelToggled(channel, value),
                        categoryEnabledMap: _categoryEnabledMap,
                        onToggleCategory: (category) => _onCategoryToggled(
                          category,
                          !(_categoryEnabledMap[category.name] ?? true),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: widget.channels.isEmpty ? 0 : AppSpacing.md),
          ],
        ),
      ),
    );
  }

  /// 切换单个渠道启用状态。
  Future<void> _onChannelToggled(ChannelConfig channel, bool enabled) async {
    await _messageState.setChannelEnabled(channel.id, enabled);
    setState(() => _enabledMap[channel.id] = enabled);

    if (channel.implemented) {
      await _autoRefresh.reloadChannel(channel.id);
    }

    if (!mounted) return;
    final message = enabled
        ? '已启用「${channel.name}」，请到信息中心刷新获取该渠道消息'
        : '已关闭「${channel.name}」，该渠道消息将不再显示';
    showAppFeedback(
      context,
      message: message,
      severity: enabled
          ? AppFeedbackSeverity.success
          : AppFeedbackSeverity.warning,
    );
  }

  /// 批量切换当前分区全部渠道。
  Future<void> _setAllChannelsEnabled(bool enabled) async {
    for (final channel in widget.channels) {
      await _messageState.setChannelEnabled(channel.id, enabled);
      _enabledMap[channel.id] = enabled;
      if (channel.implemented) {
        await _autoRefresh.reloadChannel(channel.id);
      }
    }

    if (enabled) {
      for (final subcategoryList in channelSubcategories.values) {
        for (final subcategory in subcategoryList) {
          await _messageState.setCategoryEnabled(
            subcategory.category.name,
            true,
          );
          _categoryEnabledMap[subcategory.category.name] = true;
        }
      }
    }

    if (!mounted) return;
    setState(() {});
    showAppFeedback(
      context,
      message: enabled ? '已启用当前分区全部渠道' : '已关闭当前分区全部渠道',
      severity: enabled
          ? AppFeedbackSeverity.success
          : AppFeedbackSeverity.info,
    );
  }

  Future<void> _onGroupManualCountChanged(int count) async {
    final normalized = count.clamp(1, 200);
    for (final channel in widget.channels.where((item) => item.implemented)) {
      await _messageState.setChannelManualFetchCount(channel.id, normalized);
      _manualCountMap[channel.id] = normalized;
    }
    setState(() => _groupManualCount = normalized);
  }

  Future<void> _onGroupAutoRefreshToggled(bool enabled) async {
    final interval = _groupInterval <= 0 ? 60 : _groupInterval;
    for (final channel in widget.channels.where((item) => item.implemented)) {
      if (enabled) {
        await _messageState.setChannelInterval(channel.id, interval);
      } else {
        await _messageState.setChannelAutoRefreshEnabled(channel.id, false);
      }
      _autoRefreshEnabledMap[channel.id] = enabled;
      _intervalMap[channel.id] = interval;
      await _autoRefresh.reloadChannel(channel.id);
    }

    setState(() {
      _groupAutoRefreshEnabled = enabled;
      _groupInterval = interval;
    });
  }

  Future<void> _onGroupIntervalChanged(int minutes) async {
    for (final channel in widget.channels.where((item) => item.implemented)) {
      await _messageState.setChannelInterval(channel.id, minutes);
      _intervalMap[channel.id] = minutes;
      _autoRefreshEnabledMap[channel.id] = minutes > 0;
      await _autoRefresh.reloadChannel(channel.id);
    }

    setState(() {
      _groupInterval = minutes;
      _groupAutoRefreshEnabled = minutes > 0;
    });
  }

  Future<void> _onGroupAutoCountChanged(int count) async {
    final normalized = count.clamp(1, 200);
    for (final channel in widget.channels.where((item) => item.implemented)) {
      await _messageState.setChannelAutoFetchCount(channel.id, normalized);
      _autoCountMap[channel.id] = normalized;
      await _autoRefresh.reloadChannel(channel.id);
    }

    setState(() => _groupAutoCount = normalized);
  }

  Future<void> _onCategoryToggled(
    MessageCategory category,
    bool enabled,
  ) async {
    await _messageState.setCategoryEnabled(category.name, enabled);
    setState(() => _categoryEnabledMap[category.name] = enabled);
  }
}

/// 职能部门 / 教学单位分区总览。
class _ChannelSectionOverview extends StatelessWidget {
  const _ChannelSectionOverview({
    required this.title,
    required this.totalCount,
    required this.implementedCount,
    required this.enabledCount,
    required this.autoEnabledCount,
    required this.onEnableAll,
    required this.onDisableAll,
  });

  /// 分区标题。
  final String title;

  /// 渠道总数。
  final int totalCount;

  /// 已接入渠道数。
  final int implementedCount;

  /// 已启用渠道数。
  final int enabledCount;

  /// 自动刷新开启数。
  final int autoEnabledCount;

  /// 启用全部渠道。
  final VoidCallback onEnableAll;

  /// 关闭全部渠道。
  final VoidCallback onDisableAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.fluentColors;
    final type = context.fluentType;

    return FluentCard(
      padding: EdgeInsets.zero,
      bordered: true,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shouldStack = shouldStackSettingsControls(constraints);
            final titleBlock = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FluentSurfaceIcon(icon: FluentIcons.news),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: type.subtitle1),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '统一管理学校官网消息来源，启用后会在信息中心筛选和刷新中生效。',
                        style: type.caption1.copyWith(
                          color: colors.neutralForeground2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              alignment: shouldStack ? WrapAlignment.start : WrapAlignment.end,
              children: [
                FluentButton.primaryIcon(
                  onPressed: onEnableAll,
                  icon: const Icon(FluentIcons.checkMark),
                  label: const Text('一键全开'),
                ),
                FluentButton.outlineIcon(
                  onPressed: onDisableAll,
                  icon: const Icon(FluentIcons.blocked),
                  label: const Text('一键全关'),
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shouldStack) ...[
                  titleBlock,
                  const SizedBox(height: AppSpacing.md),
                  actions,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleBlock),
                      const SizedBox(width: AppSpacing.md),
                      actions,
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FluentStatusChip(
                      label: '共 $totalCount 个渠道',
                      tone: FluentStatusChipTone.neutral,
                      icon: FluentIcons.list,
                    ),
                    FluentStatusChip(
                      label: '已接入 $implementedCount 个',
                      tone: FluentStatusChipTone.brand,
                      icon: FluentIcons.plugConnected,
                    ),
                    FluentStatusChip(
                      label: '已启用 $enabledCount 个',
                      tone: enabledCount > 0
                          ? FluentStatusChipTone.success
                          : FluentStatusChipTone.neutral,
                      icon: FluentIcons.checkMark,
                    ),
                    FluentStatusChip(
                      label: '自动刷新 $autoEnabledCount 个',
                      tone: autoEnabledCount > 0
                          ? FluentStatusChipTone.brand
                          : FluentStatusChipTone.neutral,
                      icon: FluentIcons.sync,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
