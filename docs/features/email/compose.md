# 撰写发送

> 模块：[邮箱](README.md)　·　状态：**已实现**（纯文本与附件选择、校验、MIME 发送已接通）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `email.compose` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/email_service.dart`（`sendMessage`）；`lib/models/email_mailbox.dart`（`EmailComposeRequest`） |

## 1. 需求

用户主动撰写并通过 SMTP 发送邮件：纯文本正文 + To/Cc/Bcc + **附件**。

**验收要点**
- 仅在用户主动点击发送时发信；不自动发送、不后台重试、不撤回。
- 支持附件：单封总大小 ≤ 100MB、附件数 ≤ 25 个。
- 沿用现有输入校验；发信明文不入日志与普通缓存。

## 2. 交互与界面

- 撰写表单：To/Cc/Bcc、主题、纯文本正文、附件添加/移除。
- 提交后展示脱敏状态（成功/被拒/网络失败），不回显完整收件人或正文。
- 在现有清源撰写面板中增加附件选择、清单、移除与校验反馈。

## 3. 实现

### 3.1 发信

- `EmailService.sendMessage(EmailComposeRequest)` 经 SMTP（`smtp.exmail.qq.com:465` SSL）发送。
- 账号固定 `学工号@sspu.edu.cn` + 独立邮箱密码。

### 3.2 校验（沿用 + 扩展）

| 项 | 限制 |
| --- | --- |
| 收件人 | To 至少 1 个；To+Cc+Bcc 合计 ≤ 50 |
| 主题 | 非空，≤ 200 字符 |
| 正文 | 非空，≤ 20000 字符（纯文本） |
| 地址格式 | To/Cc/Bcc 逐项格式校验 |
| **附件** | **单封总大小 ≤ 100MB，附件数 ≤ 25 个** |

- `EmailComposeRequest` 已扩展本地文件路径、文件名、MIME 类型与大小字段。
- 附件随 SMTP 以 MIME multipart 发送，复用 `enough_mail` 的 `MessageBuilder.addFile`，不自行拼接 MIME 边界。
- 文件选择阶段会立即说明重复、无效、超大或数量超限的附件；发送使用单飞锁，同一次用户提交不会被静默重试或重复投递。

## 4. 关联

- 依赖：[登录与凭据](../academic/auth-credentials.md)（邮箱密码）。
- 关联：[收件箱与阅读](inbox.md)（共享账号/端点）。

## 5. 约束

- **用户主动发送**：不自动发送、不定时、不后台重试、不静默重发；提交后以服务端状态为准。
- 收件人、抄送、密送、主题、正文、附件仅用于本次 SMTP 请求，**不写入普通缓存、不进日志**；反馈只展示脱敏文案。
- 附件大小/数量超限即在本地拦截并提示。

## 6. 待办与演进

- [x] `EmailComposeRequest` 扩展附件字段；SMTP MIME multipart 发送。
- [x] 附件大小（≤100MB）/数量（≤25）及文件存在性本地校验。
- [x] `EMAIL_RULES.md` 已放开发信附件并写明数量、大小、隐私与 MIME 复用边界。
- [ ] **后续**：草稿保存、回复/转发、富文本。
