part of 'channel_config.dart';

// ==================== 微信渠道 ====================

/// 微信渠道配置列表
/// 仅暴露已经接入抓取链路的微信推文渠道，避免设置页出现不可用入口。
const List<ChannelConfig> wechatChannels = [
  ChannelConfig(
    id: 'wechat_public',
    name: '微信公众号',
    description: '通过公众号平台获取已关注公众号的推文',
    icon: FluentIcons.chat,
    group: ChannelGroup.wechat,
    implemented: true,
    defaultInterval: 120,
    defaultEnabled: true,
  ),
];
