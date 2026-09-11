# 微信公众号文章

> 模块：[资讯](README.md)　·　状态：**部分实现**（认证、固定账号抓取与公众号/服务号统一刷新已完成；真实平台认证待验证）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `info.wechat-articles` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/wxmp_*.dart`、`wechat_article_service.dart`、`wxmp_config_service.dart`、`wxmp_auth_service.dart`；`lib/models/channel_config_wechat.dart`、`sspu_wechat_accounts.dart` |

## 1. 需求

抓取**固定校内公众号与服务号**的推文，统一为 `MessageItem` 汇入 [消息中心](message-center.md)。公众号与服务号只是展示来源差异，必须共享同一认证、抓取、刷新、去重和通知意愿链路。本期移除面向用户的自定义订阅管理。

**验收要点**
- 经扫码登录获取平台 cookie/token 后抓取公众号文章。
- 仅抓取**内置固定公众号**集合，不提供用户自定义订阅增删。
- 文章作为微信推文消息汇入消息中心，支持单公众号通知意愿。

## 2. 标签特殊性（两级）

- 微信内容**仅两级标签**：tag1 来源类型（微信推文/服务号）+ tag2 账号名称；**无 tag3 内容分类**。
- `MessageItem` 的 `mpBookId` / `mpName` / `mpDisplayId` 承载公众号标识与展示。

## 3. 实现

### 3.1 登录与配置（沿用现有）

- `wxmp_auth_service`：**扫码登录**获取平台 cookie/token（用于抓取授权）。
- `wxmp_config_service` + `wxmp_config.toml`：平台认证配置（设置页内置编辑器）。
- 登录态/敏感 token 进系统安全存储或受保护配置，不入日志。

### 3.2 文章抓取

- `wxmp_article_fetch` / `wechat_article_service`：按内置固定账号集合（`sspu_wechat_accounts`）抓取最近文章 → `MessageItem`；公众号与服务号不再分成两套刷新任务。
- 抓取条数/间隔随频道配置（`wechat_public` 默认条数 10）。
- 同一刷新批次会在分页和多账号合并阶段按文章 ID 去重；通知层也只消费去重后的新增消息。
- 统一刷新结果区分认证/会话/CSRF 失效、频率限制与单来源失败；部分来源成功时保留文章并报告成功/失败计数，设置与手动刷新入口据此提示重新扫码或稍后重试。
- **去掉 `following` 订阅管理**：不再提供用户自定义关注/取关公众号。

### 3.3 通知意愿

- 保留**单公众号通知开关**（`isMpNotificationEnabled`，按 `mpBookId`）；投递归 [通知与提醒](../platform/system/notifications.md)。
- 通知意愿与文章抓取分离：关闭某来源通知后，刷新仍会保存该来源文章到消息中心，只跳过系统通知。

## 4. 关联

- 被依赖：[消息中心](message-center.md)（消费微信推文消息）；[通知与提醒](../platform/system/notifications.md)（单公众号通知意愿）。
- 依赖：[设置中心](../platform/shell/settings.md)（`wxmp_config.toml` 编辑、扫码登录入口）；[本地存储](../platform/system/storage-sync.md)。

## 5. 约束

- 仅抓取固定公众号，**不做用户自定义订阅**。
- 平台 cookie/token 等敏感信息进安全存储、不入日志与普通缓存。
- 扫码登录的平台差异（移动/桌面）以运行时能力为准。

## 6. 待办与演进

- [x] 以固定账号映射替代面向用户的 `following` 订阅管理路径，同时保留平台内部所需的账号解析能力。
- [x] 清源扫码登录、认证状态与 `wxmp_config.toml` 内置编辑器。
- [x] 将公众号与服务号合并到同一刷新、去重和错误反馈链路，不再维护“服务号刷新”占位定时器。
- [x] 单公众号通知意愿对接 [通知与提醒](../platform/system/notifications.md)；通知投递层按 `mpBookId` 过滤，并交由通知服务统一投递。
- [x] 通知意愿与文章抓取完全解耦，关闭通知不阻断手动或定时刷新。
