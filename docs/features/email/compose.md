# 撰写发送

> 模块：[邮箱](README.md)　·　状态：**部分实现**（纯文本发信已实现，新增附件）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `email.compose` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/email_service.dart`（`sendMessage`）；`lib/models/email_mailbox.dart`（`EmailComposeRequest`） |

## 1. 需求

用户主动撰写并通过 SMTP 发送邮件：纯文本正文 + To/Cc/Bcc + **附件**。

**验收要点**
- 仅在用户主动点击发送时发信；不自动发送、不后台重试、不撤回。
- 支持附件：单封总大小 ≤ 100MB、附件数 ≤ 25 个。
- 沿用现有输入校验；发信明文不入日志与普通缓存。

## 2. 交互与界面（期望行为，前端重构后落地）

- 撰写表单：To/Cc/Bcc、主题、纯文本正文、附件添加/移除。
- 提交后展示脱敏状态（成功/被拒/网络失败），不回显完整收件人或正文。
- 组件形态由设计系统与前端重构决定，本文档只约束**字段与校验语义**。

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

- `EmailComposeRequest` 需扩展附件字段（文件路径/字节、文件名、MIME 类型）。
- 附件随 SMTP 以 MIME multipart 发送。

## 4. 关联

- 依赖：[登录与凭据](../academic/auth-credentials.md)（邮箱密码）。
- 关联：[收件箱与阅读](inbox.md)（共享账号/端点）。

## 5. 约束

- **用户主动发送**：不自动发送、不定时、不后台重试、不静默重发；提交后以服务端状态为准。
- 收件人、抄送、密送、主题、正文、附件仅用于本次 SMTP 请求，**不写入普通缓存、不进日志**；反馈只展示脱敏文案。
- 附件大小/数量超限即在本地拦截并提示。

## 6. 待办与演进

- [ ] `EmailComposeRequest` 扩展附件字段；SMTP MIME multipart 发送。
- [ ] 附件大小（≤100MB）/数量（≤25）本地校验与提示。
- [ ] 同步更新 `EMAIL_RULES.md` 的发信边界（放开附件）。
- [ ] **后续**：草稿保存、回复/转发、富文本。
