# 设置中心

> 子模块：[壳层](README.md)　·　状态：**已实现**

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

| 分区 | 内容 | 状态 | 归属功能 |
| --- | --- | --- | --- |
| 常规 | 主页区域显隐、服务摘要显隐/排序、模块联网获取、普通消息/课程/考试提醒、通知权限状态、勿扰与关闭行为 | 已实现 | [主页仪表盘](home-dashboard.md)、[通知与提醒](../system/notifications.md) |
| 学期 | 查询使用学期、校历入口 | 已实现 | [校历](../academic-calendar.md) |
| 自动刷新 | 校园数据独立开关、共享间隔与消息来源入口 | 已实现 | [后台自动刷新](../system/auto-refresh.md) |
| 安全 | 锁屏、凭据、数据与隐私入口 | 已实现 | [安全锁屏与隐私](../system/security-privacy.md)、[登录与凭据](../../academic/auth-credentials.md) |
| 职能部门 / 教学单位 | 资讯来源、抓取条数与自动刷新配置 | 已实现 | [消息中心](../../info/message-center.md) |
| 微信推文 | `wxmp_config.toml`、扫码登录、公众号开关与统一刷新 | 部分实现；真实平台认证待验证 | [微信公众号文章](../../info/wechat-articles.md) |
| 外观 | 亮色、暗色、跟随系统 | 已实现 | [主题与深色模式](../personalization/theme.md) |
| 更新 | 渠道、检查、下载与校验 | 已实现 | [应用更新检测](../system/app-update.md) |
| 关于 | 版本、设计语言、开源许可与法律说明 | 已实现 | platform |

WebDAV、界面语言、AI 与 VPN 当前没有设置入口；其中 VPN 已按 #169 明确不再计划，其他能力仍以各自功能文档为准。

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

- [x] 清源设置分区、响应式导航与卡片显隐/排序配置（#187）。
- [x] 为各数据域增加独立“停止获取”开关，并与手动/自动刷新和详情入口联动（#187）。
