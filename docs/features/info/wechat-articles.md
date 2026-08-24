# 微信公众号文章

> 模块：[资讯](README.md)　·　状态：**部分实现**（登录/抓取层已实现，简化订阅 + 前端重构）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `info.wechat-articles` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/wxmp_*.dart`、`wechat_article_service.dart`、`wxmp_config_service.dart`、`wxmp_auth_service.dart`；`lib/models/channel_config_wechat.dart`、`sspu_wechat_accounts.dart` |

## 1. 需求

抓取**固定校内公众号**的推文，统一为 `MessageItem`（微信推文源）汇入 [消息中心](message-center.md)。本期**简化：去掉用户自定义订阅管理**。

**验收要点**
- 经扫码登录获取平台 cookie/token 后抓取公众号文章。
- 仅抓取**内置固定公众号**集合，不提供用户自定义订阅增删。
- 文章作为微信推文消息汇入消息中心，支持单公众号通知意愿。

## 2. 标签特殊性（两级）

- 微信推文**仅两级标签**：tag1 来源类型（微信推文）+ tag2 公众号名称；**无 tag3 内容分类**。
- `MessageItem` 的 `mpBookId` / `mpName` / `mpDisplayId` 承载公众号标识与展示。

## 3. 实现

### 3.1 登录与配置（沿用现有）

- `wxmp_auth_service`：**扫码登录**获取平台 cookie/token（用于抓取授权）。
- `wxmp_config_service` + `wxmp_config.toml`：平台认证配置（设置页内置编辑器）。
- 登录态/敏感 token 进系统安全存储或受保护配置，不入日志。

### 3.2 文章抓取

- `wxmp_article_fetch` / `wechat_article_service`：按内置固定公众号集合（`sspu_wechat_accounts`）抓取最近文章 → `MessageItem`（微信推文）。
- 抓取条数/间隔随频道配置（`wechat_public` 默认条数 10）。
- **去掉 `following` 订阅管理**：不再提供用户自定义关注/取关公众号。

### 3.3 通知意愿

- 保留**单公众号通知开关**（`isMpNotificationEnabled`，按 `mpBookId`）；投递归 [通知与提醒](../platform/system/notifications.md)。

## 4. 关联

- 被依赖：[消息中心](message-center.md)（消费微信推文消息）；[通知与提醒](../platform/system/notifications.md)（单公众号通知意愿）。
- 依赖：[设置中心](../platform/shell/settings.md)（`wxmp_config.toml` 编辑、扫码登录入口）；[本地存储](../platform/system/storage-sync.md)。

## 5. 约束

- 仅抓取固定公众号，**不做用户自定义订阅**。
- 平台 cookie/token 等敏感信息进安全存储、不入日志与普通缓存。
- 扫码登录的平台差异（移动/桌面）以运行时能力为准。

## 6. 待办与演进

- [ ] 简化为固定公众号抓取，移除 `following` 订阅管理路径。
- [ ] 扫码登录与 `wxmp_config.toml` 编辑随前端重构对接。
- [ ] 单公众号通知意愿对接 [通知与提醒](../platform/system/notifications.md)。
