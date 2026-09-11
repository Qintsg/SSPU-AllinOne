# MCP Tool Catalog

**MVP rule**: 所有工具只读取本地快照，均标记 read-only、non-destructive、idempotent；未授权
工具不出现在 `tools/list`，也无法通过已缓存名称绕过 `tools/call` 授权。

## Common conventions

- Tool name 永久使用 snake_case；重命名视为破坏性契约变更。
- 输入 JSON Schema 使用 `additionalProperties: false`。
- 列表统一接受 `limit`（默认 25，最大 100）和不透明 `cursor`。
- 所有输出包裹在 `McpSnapshotEnvelope`，包含 `status`、`snapshotAt`、`isStale`、`data`，
  列表另含 `page`。
- DTO 只从明确 allowlist 字段构造；不得透传业务模型的 `toJson()`。
- `sourceUri`、`rawFields`、`rawCells`、本地路径、账号密码、Cookie、Token、API Key、附件内容
  与缓存 owner 信息一律禁止。

## Release wave A: 核心学习与校园卡数据

### `get_current_profile`

- **Domain**: `profile`
- **Purpose**: 为“我的专业/班级/培养层次是什么”等个性化问答提供当前学籍摘要。
- **Input**: `{}`
- **Data output allowlist**:
  - `displayName`
  - `studentId`
  - `department`
  - `major`
  - `className`
  - `educationLevel`
  - `studyLength`
- **Excluded**: gender 默认不返回；原始学籍字段、账号凭据与来源地址永不返回。

### `list_schedule`

- **Domain**: `coursesAndExams`
- **Purpose**: 查询本地课表，支持 Agent 回答今天/本周课程。
- **Input**: `limit?: 1..100`、`cursor?: string`。MVP 返回当前本地课表快照；按日期/周次
  筛选需先由客户端基于 `weekday` 与 `weekPattern` 解释，后续版本再增加服务端学期日历索引。
- **Item output allowlist**:
  - `courseName`
  - `teacherName`
  - `location`
  - `weekday`
  - `startPeriod`, `endPeriod`
  - `weekPattern`
  - `termName`
- **Ordering**: week/date、weekday、startPeriod、courseName。

### `list_exams`

- **Domain**: `coursesAndExams`
- **Purpose**: 查询本地考试安排。
- **Input**: `limit?: 1..100`、`cursor?: string`。MVP 以本地快照当前考试类型为范围；日期筛选
  待考试日期结构化后再开放。
- **Item output allowlist**:
  - `courseName`
  - `examType`
  - `date`
  - `arrangement`
  - `location`
  - `status`
- **Ordering**: date/time、courseName。

### `list_grades`

- **Domain**: `gradesAndProgram`
- **Purpose**: 查询当前或历史成绩。
- **Input**:
  - `scope?: current_term|history|all`，默认 `current_term`
  - `term?: string`
  - `limit?: 1..100`
  - `cursor?: string`
- **Item output allowlist**:
  - `courseName`
  - `termName`
  - `score`
  - `scoreText`
  - `credits`
  - `courseNature`
  - `gradePoint`
- **Excluded**: 原始表格单元格、请求地址和未解释的内部 ID。

### `get_program_progress`

- **Domain**: `gradesAndProgram`
- **Purpose**: 返回培养计划完成摘要和按模块进度。
- **Input**: `{}`
- **Data output allowlist**:
  - `completedCourseCount`, `pendingCourseCount`
  - `completedCredits`, `pendingCredits`
  - `modules[]`: `name`, `requiredCredits`, `completedCredits`, `pendingCredits`,
    `completedCourseCount`, `pendingCourseCount`
- **Result limit**: modules 最多 100；超出只返回汇总和分页错误，不静默截断。

### `get_second_classroom_credits`

- **Domain**: `secondClassroom`
- **Purpose**: 读取已有的第二课堂学分汇总和逐项认定记录。
- **Input**: `limit?: 1..100`、`cursor?: string`
- **Item output allowlist**:
  - `category`
  - `itemName`
  - `credit`
  - `semester`
  - `occurredAt`
  - `status`
- **Summary output allowlist**: 总学分、已获学分、要求学分与通过状态。
- **Excluded**: 原始表格单元格、OA 地址和登录材料。

### `get_campus_card_summary`

- **Domain**: `campusCard`
- **Purpose**: 返回余额与卡状态，不返回交易流水。
- **Input**: `{}`
- **Data output allowlist**:
  - `balance`
  - `currency`（固定 `CNY`）
  - `cardStatus`
- **Excluded**: 卡号、支付凭据、交易记录、来源 URI。

### `list_campus_card_transactions`

- **Domain**: `campusCard`
- **Purpose**: 查询已有快照中的校园卡交易。
- **Input**:
  - `from?: YYYY-MM-DD`
  - `to?: YYYY-MM-DD`，跨度最多 90 天
  - `direction?: debit|credit|all`，默认 `all`
  - `limit?: 1..100`
  - `cursor?: string`
- **Item output allowlist**:
  - `occurredAt`
  - `amount`
  - `currency`（固定 `CNY`）
  - `direction`
  - `merchant`
  - `type`
  - `balanceAfter`
  - `status`
- **Excluded**: transactionId、counterparty、paymentMethod 默认不返回，避免不必要的关联标识。

## Release wave B: 文本型数据

### `search_messages`

- **Domain**: `messages`
- **Sensitivity**: `sensitiveText`
- **Purpose**: 在应用已有消息快照中搜索标题与摘要。
- **Input**:
  - `query?: string`，1–100 字符；省略时返回最近消息
  - `from?: YYYY-MM-DD`
  - `to?: YYYY-MM-DD`，跨度最多 365 天
  - `source?: string`
  - `limit?: 1..100`
  - `cursor?: string`
- **Item output allowlist**:
  - `title`
  - `summary`（最多 300 字符）
  - `publishedDate`
  - `sourceName`
  - `category`
- **Excluded**: 外链 URL 中的 query/fragment、浏览状态内部 ID、原始 HTML。

### `search_email`

- **Domain**: `email`
- **Sensitivity**: `sensitiveText`
- **Purpose**: 搜索已有邮箱列表快照；MVP 不取服务器、不下载附件、不返回完整正文。
- **Input**:
  - `query?: string`，1–100 字符；仅匹配本地 subject/sender/preview
  - `from?: YYYY-MM-DD`
  - `to?: YYYY-MM-DD`，跨度最多 365 天
  - `folder?: inbox|sent|all`，默认 `inbox`，仅支持本地已有文件夹
  - `limit?: 1..100`
  - `cursor?: string`
- **Item output allowlist**:
  - `messageId`（MCP 专用不透明 ID，不等于服务器 UID）
  - `subject`
  - `senderDisplayName`
  - `senderAddress`
  - `receivedAt`
  - `preview`（最多 300 字符）
  - `hasAttachments`
- **Excluded**: 收件账号、完整正文、附件名/内容/路径、协议端点、服务器 UID、认证材料。
- **Future split**: 如需正文，新增独立的 `get_email_message_body` 工具和独立授权，不向
  `search_email` 增加 `includeBody` 开关。

## Release wave C: 后续扩展域

这些能力属于 FR-012 规划范围，但不是 MVP 九工具的一部分；必须在数据源已形成可靠本地快照和
独立验收标准后加入：

| Candidate | Domain | Boundary |
| --- | --- | --- |
| `list_campus_activities` | `campusActivities` | 只返回公开活动摘要和本地收藏状态，不代报名/预约 |
| `get_safe_app_preferences` | `appPreferences` | 固定白名单，如主题与提醒偏好；不得导出整个 app_state.json |
| `get_email_message_body` | `email` | 独立高敏感授权；正文长度上限；仍不返回附件 |

新增工具必须更新规格、目录、本地化授权文案、契约测试和敏感字段扫描；不能因为用户已授权某个
domain 就自动启用未来新增工具。

## Capability-to-requirement traceability

| Requirement | Tools / control |
| --- | --- |
| FR-011/FR-012 | 每个 catalog entry 对应独立默认关闭 grant，并按 domain 分组 |
| FR-013/FR-014 | 每个工具的 allowlist/excluded 字段与统一分页上限 |
| FR-015 | 所有 handler 仅使用 snapshot adapter，输出 `snapshotAt/isStale` |
| FR-016 | 全部 annotations 为 read-only/non-destructive，不注册写工具 |
| FR-017 | list 和 call 双重授权，返回前 generation 复检 |
| FR-021 | limit/cursor、文本长度、日期跨度、超时与响应体上限 |
