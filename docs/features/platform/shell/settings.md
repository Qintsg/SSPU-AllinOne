# 设置中心

> 子模块：[壳层](README.md)　·　状态：**已实现**（前端重构 + 卡片显隐配置）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.shell.settings` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #187 |
| 主要代码 | `lib/pages/settings_page*.dart`；`lib/widgets/settings_*.dart`；`lib/controllers/settings_wechat_*.dart` |

## 1. 需求

统一的设置入口，分区承载各功能配置；并统一管理主页卡片/模块的显隐与排序（#187）。

## 2. 设置分区（汇总）

| 分区 | 内容 | 归属功能 |
| --- | --- | --- |
| 通用 | 显示名、基础项 | platform |
| 主页卡片 | 卡片显隐 + 排序（#187） | [主页仪表盘](home-dashboard.md) |
| 学期设置 | 查询使用学期 | [校历](../academic-calendar.md) |
| 自动刷新 | 校园数据独立开关、共享间隔与消息来源入口 | [后台自动刷新](../system/auto-refresh.md) |
| 安全与凭据 | 锁屏、学工号/密码状态 | [安全锁屏与隐私](../system/security-privacy.md)、[登录与凭据](../../academic/auth-credentials.md) |
| 数据管理 | 本地数据、WebDAV 同步（#194） | [本地存储与同步](../system/storage-sync.md) |
| 通知 | 全局开关、勿扰、提醒（#188） | [通知与提醒](../system/notifications.md) |
| 公众号 | `wxmp_config.toml`、扫码登录 | [微信公众号文章](../../info/wechat-articles.md) |
| 主题 | 深色模式/主题（#168） | [主题与深色模式](../personalization/theme.md) |
| 语言 | 界面语言（#192） | [国际化](../personalization/i18n.md) |
| 更新 | 渠道、检查更新 | [应用更新检测](../system/app-update.md) |
| AI | BYOK、授权矩阵、MCP 暴露 | [AI 助手](../../ai/README.md) |
| VPN | 自动连接开关（仅桌面） | [VPN 一键连接](../../network/vpn-connect.md) |

## 3. 实现

- `settings_page` + 分区组件（`settings_*`）+ 公众号控制器；校园数据间隔经共享偏好模块统一落盘，其余设置项落 [本地存储](../system/storage-sync.md) 或安全存储。
- 卡片显隐/排序配置作为 #187 的统一入口，供 [主页仪表盘](home-dashboard.md) 渲染。

## 4. 关联

- 被依赖：几乎所有功能在此暴露用户可见配置。
- 依赖：[本地存储](../system/storage-sync.md)、[安全锁屏与隐私](../system/security-privacy.md)。

## 5. 约束

- 敏感项（凭据/Key/Token）经安全存储，设置页只显示状态、不回显明文。
- 配置项默认值后续可按需调整。

## 6. 待办与演进

- [ ] 前端重构后的设置分区与卡片显隐/排序配置（#187）。
