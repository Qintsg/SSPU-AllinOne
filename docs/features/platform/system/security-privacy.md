# 安全锁屏与隐私

> 子模块：[系统能力](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.system.security-privacy` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/system_auth_service.dart`、`password_service.dart`；`lib/pages/lock_page.dart`、`agreement_page.dart`、`privacy_policy_page.dart`、`legal_notice_page.dart`；`lib/legal/`；`flutter_secure_storage` |

## 1. 需求

保护本地数据访问并满足隐私合规：应用锁屏（系统生物识别/密码）、敏感凭据安全存储、法律与隐私协议展示与同意。

## 2. 实现

- **锁屏**：`system_auth_service` 调系统生物识别/设备密码；`password_service` 管理应用密码哈希；`lock_page` 解锁界面。
- **安全存储**：凭据/Token/Key 经 `flutter_secure_storage`；学籍等敏感数据加密缓存；不写 `app_state.json`。
- **隐私协议**：首次启动展示完整法律与隐私说明（`legal/`、`agreement_page`、`privacy_policy_page`、`legal_notice_page`），关于页可随时查看。

## 3. 关联

- 被依赖：[登录与凭据](../../academic/auth-credentials.md)、[AI 模型与数据边界](../../ai/model-data-boundary.md)、[MCP 暴露](../../ai/mcp-server.md)（Token 安全存储）及一切敏感数据存取。
- 依赖：[本地存储](storage-sync.md)。

## 4. 约束

- 敏感信息进安全存储/加密缓存，不进日志与普通缓存。
- 协议同意状态本地记录；隐私说明与安装器许可页保持同步。

## 5. 待办与演进

- [x] 清源锁屏、系统快速验证、法律说明与隐私协议展示。
