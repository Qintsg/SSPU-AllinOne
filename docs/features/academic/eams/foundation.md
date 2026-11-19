# EAMS 基座

> 子模块：[EAMS 教务](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.foundation` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #353 |
| 主要代码 | `lib/services/academic_eams_service.dart`、`lib/services/academic_portal_queries.dart`、`lib/services/academic_portal_parsers.dart` |

## 1. 职责

为新版教务提供统一身份认证、账号校验、只读请求和缓存。

## 2. 基座组成

### 2.1 会话与入口

- 应用从 `jw.sspu.edu.cn` 进入学校统一身份认证，教务会话与其它 OA 功能分别缓存。
- 读取前核对会话中的学生身份与保存的学号。失效会话更新后，再重试一次教务查询。
- 新版数据读取使用 GET。多个模块同时刷新时，单项失败会保留已读取的其它模块数据。

### 2.2 快照与缓存

- 统一快照 `AcademicEamsSnapshot`：profile / courseTable / grades / gradeProcess / programPlan / programCompletion / exams / courseOfferingsPreview / freeClassroomsPreview + warnings + 入口可用标记。
- per-account 缓存（`AuthenticatedDataCacheService`），各功能独立 collection；学籍 profile 走加密缓存。
- 抓取范围 `_AcademicFetchScope`：overview / courseTableOnly / examScheduleOnly / gradesOnly / gradeProcessOnly。

### 2.3 状态枚举

`AcademicEamsQueryStatus`：success / partialSuccess / missingOaAccount / missingOaPassword / campusNetworkUnavailable / oaLoginRequired / systemUnavailable / readOnlyEntryUnavailable / queryFormUnavailable / parseFailed / networkError / unexpectedError。

## 3. 关联

- 依赖：[登录与凭据](../auth-credentials.md)、[network 门禁](../../network/network-status.md)、[后台自动刷新](../../platform/system/auto-refresh.md)、[本地存储](../../platform/system/storage-sync.md)。
- 被依赖：本子系统全部功能。

## 4. 约束

- **严格只读**：`submitForm` 仅查询；任何写操作禁止。
- 解析失败降级（`parseFailed`）、单模块失败用 `partialSuccess` 不阻断整体。
- 敏感会话/学籍不进日志；缓存按账号隔离、存系统默认应用数据目录。
