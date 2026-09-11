# 登录与凭据

> 模块：[教务](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.auth-credentials` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/academic_login_*.dart`、`academic_credentials_service.dart`、`academic_login_validation_service.dart`、`academic_oa_session_prewarm_service.dart`；`lib/models/academic_credentials.dart`、`academic_login_validation.dart` |

## 1. 需求

作为教务、校园卡、邮箱等受限功能的**统一登录与凭据底座**：保存凭据、维护 OA/CAS 会话、校验登录状态。

**验收要点**
- 凭据（学工号、OA 密码、邮箱密码）进系统安全存储，不落 `app_state.json`。
- OA/CAS 会话可复用、失效可刷新（含 prewarm 预热）。
- 登录校验返回结构化状态，失败给可读原因。

## 2. 凭据与会话

- **凭据**：学工号（OA 账号）、OA 密码、邮箱密码，经 `flutter_secure_storage` 存储（`AcademicCredentialSecret`）。
- **学籍信息**：`AcademicEamsProfile` 加密缓存（绑定 OA 账号）。
- **会话**：OA/CAS 登录产出 cookie 会话快照，供各业务网关注入；`academic_oa_session_prewarm_service` 预热会话降低首查延迟。
- **登录加密**：`academic_login_crypto` 处理 CAS 表单加密；`academic_login_form`/`academic_login_gateway` 负责表单与提交。

## 3. 实现

- `AcademicCredentialsService`（单例）：凭据读写、状态查询、学籍缓存、会话快照读写。
- `AcademicLoginValidationService.ensureSavedSession({forceRefresh, requireCampusNetwork})`：保证可用会话，被各业务的 `refreshOaLogin` 复用。
- 凭据变更时正在进行的查询应丢弃结果（各业务已实现该保护）。

## 4. 关联

- 被依赖：[EAMS 基座](eams/foundation.md) 及全部 EAMS 功能、[体育打卡](activity/sports-attendance.md)、[第二课堂](activity/student-report.md)、[校园卡](../campus-life/campus-card.md)、[邮箱](../email/README.md)。
- 依赖：[network 门禁](../network/network-status.md)（会话刷新前可选门禁）、[安全锁屏与隐私](../platform/system/security-privacy.md)（安全存储）。

## 5. 约束

- 凭据/会话/学籍均进安全存储或加密缓存；不进日志与普通缓存。
- 仅维护本校 OA/CAS 会话，不代理第三方登录态。
- 账号或密码变更后需失效旧会话与按账号缓存。

## 6. 待办与演进

- [x] 清源设置页中的登录、凭据填写与连接状态展示。
- [x] 会话预热、失效刷新与凭据变更后的旧结果丢弃。
- [ ] 持续维护学校登录页面改版后的解析兼容性。
