# 收件箱与阅读

> 模块：[邮箱](README.md)　·　状态：**部分实现**（基础收信/缓存已实现，前端重构 + 新增分页/搜索/已读/附件）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `email.inbox` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/email_service.dart`、`email_gateway.dart`、`email_support.dart`；`lib/models/email_mailbox.dart` |

## 1. 需求

读取学校邮箱的收件邮件并阅读：列表浏览、分页加载更早邮件、阅读正文与附件、已读/未读、本地搜索。

**验收要点**
- 默认 IMAP 收信，POP 作为可选备用。
- 列表分页加载更早邮件并累积本地缓存。
- 打开邮件可阅读正文与查看/下载附件。
- 已读/未读经 IMAP 回写 `\Seen`（仅 IMAP）。
- 本地缓存内按主题/发件人/正文搜索。
- 无校园网门禁（走公网腾讯 exmail 端点）。

## 2. 交互与界面（期望行为，前端重构后落地）

- 收件箱列表（新→旧）：发件人、主题、预览、时间、已读/未读标识；底部「加载更早」。
- 邮件详情：正文 + 附件列表（查看/下载）；打开即按已读语义处理。
- 搜索框：本地缓存内即时筛选。
- 组件形态由设计系统与前端重构决定，本文档只约束**数据语义与可用动作**。

## 3. 实现

### 3.1 协议与账号

- 端点：腾讯 exmail（IMAP `imap.exmail.qq.com:993`、POP `pop.exmail.qq.com:995`，全 SSL）。
- 账号固定 `学工号@sspu.edu.cn`，使用独立**邮箱密码**（见 [登录与凭据](../academic/auth-credentials.md)）。
- 默认 IMAP；POP 作为备用（POP 不支持文件夹/标记，能力降级）。

### 3.2 收信与缓存

- `EmailService.fetchMessages(protocol, messageCount)` 读取最近邮件；按 `账号+协议` 缓存（`AuthenticatedDataCacheService`）。
- **分页**：IMAP 按消息区间增量向更早拉取，缓存累积；POP 降级为最近 N。
- 读取过程中凭据变更则丢弃本次结果（沿用现有保护）。

### 3.3 已读/未读（唯一邮箱写操作）

- 经 IMAP `STORE \Seen` 回写服务器已读状态，与网页端同步。
- 打开邮件或手动标记时触发；**仅 IMAP**，POP 无服务器已读语义（降级为本地状态或不可用）。
- ⚠️ 这是收信侧唯一的服务器写操作，需在 `EMAIL_RULES.md` 同步放开（见模块总览）。

### 3.4 附件查看

- 解析 IMAP BODYSTRUCTURE 获取附件清单（名称/类型/大小），按需下载到本地。
- 模型 `EmailMessageSnapshot` 需扩展附件元信息字段。

### 3.5 搜索

- **本地缓存内搜索**：对已缓存邮件的主题/发件人/正文匹配；离线可用，不触发服务器 SEARCH。

### 3.6 自动刷新

- 收信自动刷新开关 + 间隔（默认 30min），归 [后台自动刷新](../platform/system/auto-refresh.md) 协同。

## 4. 关联

- 依赖：[登录与凭据](../academic/auth-credentials.md)（邮箱密码）、[本地存储](../platform/system/storage-sync.md)（缓存/附件）、[后台自动刷新](../platform/system/auto-refresh.md)。
- 关联：[撰写发送](compose.md)（共享账号/端点）；新邮件可联动 [通知与提醒](../platform/system/notifications.md)（#188，后续）。

## 5. 约束

- 收信只读，**唯一服务器写操作为 `\Seen` 回写**（仅 IMAP，用户动作触发）；不提供删除、移动、批量、自动回复/转发。
- 无校园网门禁；账号固定派生，凭据进系统安全存储。
- 邮件正文、附件、地址等不写入普通 `app_state.json`、不进日志；缓存按账号隔离、存系统默认应用数据目录。

## 6. 待办与演进

- [ ] 分页增量拉取与缓存累积（IMAP）。
- [ ] IMAP `\Seen` 回写（POP 降级策略）。
- [ ] 附件清单解析与下载，模型扩展附件字段。
- [ ] 本地缓存内搜索。
- [ ] 同步更新 `EMAIL_RULES.md` 的收信边界。
