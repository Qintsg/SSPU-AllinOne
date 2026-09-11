# EAMS 基座

> 子模块：[EAMS 教务](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.foundation` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/academic_eams_service.dart`、`academic_eams_gateway.dart`、`academic_eams_discovery.dart`、`academic_eams_page_parser*.dart`；`lib/models/academic_eams/*`、`academic_term.dart` |

## 1. 职责

为全部 EAMS 功能提供共享底座，避免在各功能重复实现登录、门禁、入口发现与缓存。

## 2. 基座组成

### 2.1 会话与入口

- 入口：OA `Entrance.jsp?id=bzkjw` → EAMS `jx.sspu.edu.cn/eams/home`。
- 会话：复用 [登录与凭据](../auth-credentials.md) 的 OA/CAS 会话；`refreshOaLogin` 在失效时强制刷新并重试入口。
- 网关 `AcademicEamsGateway`（可替换）：`resetSession`（注入 OA cookie）、`openEntryPage`、`fetchPage`、`submitForm`（**仅查询型 GET/POST**）。

### 2.2 入口发现

- `academic_eams_discovery` 经 `home!submenus.action` 枚举发现各功能入口 URI（`_AcademicFeature`：profile / courseTable / gradeCurrent / gradeHistory / programPlan / exams / courseOfferingsEntry / freeClassroomEntry），缓存于 `_discoveredFeatureUris`。
- 入口未识别 → `readOnlyEntryUnavailable`；查询表单不可识别 → `queryFormUnavailable`。

### 2.3 门禁

- 经 [network 门禁](../../network/network-status.md) 检查校园网/VPN（`requireCampusNetwork`）；不可达时刷新 OA 会话并降级（`campusNetworkUnavailable` / `oaLoginRequired`）。

### 2.4 强制中文 locale

- EAMS 账号可能为英文界面；查询需 `request_locale=zh_CN` 才能正确解析考试/表格等（见项目记忆）。基座统一注入。

### 2.5 快照与缓存

- 统一快照 `AcademicEamsSnapshot`：profile / courseTable / grades / gradeProcess / programPlan / programCompletion / exams / courseOfferingsPreview / freeClassroomsPreview + warnings + 入口可用标记。
- per-account 缓存（`AuthenticatedDataCacheService`），各功能独立 collection；学籍 profile 走加密缓存。
- 抓取范围 `_AcademicFetchScope`：overview / courseTableOnly / examScheduleOnly / gradesOnly / gradeProcessOnly。

### 2.6 状态枚举

`AcademicEamsQueryStatus`：success / partialSuccess / missingOaAccount / missingOaPassword / campusNetworkUnavailable / oaLoginRequired / systemUnavailable / readOnlyEntryUnavailable / queryFormUnavailable / parseFailed / networkError / unexpectedError。

## 3. 关联

- 依赖：[登录与凭据](../auth-credentials.md)、[network 门禁](../../network/network-status.md)、[后台自动刷新](../../platform/system/auto-refresh.md)、[本地存储](../../platform/system/storage-sync.md)。
- 被依赖：本子系统全部功能。

## 4. 约束

- **严格只读**：`submitForm` 仅查询；任何写操作禁止。
- 解析失败降级（`parseFailed`）、单模块失败用 `partialSuccess` 不阻断整体。
- 敏感会话/学籍不进日志；缓存按账号隔离、存系统默认应用数据目录。

## 5. 待办与演进

- [ ] 入口发现健壮性（学校改版时的兜底）。
- [ ] zh_CN 注入与各解析器的一致性复核。
