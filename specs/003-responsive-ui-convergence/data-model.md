# Data Model: 校园工作台响应式收敛

## AcademicGradeRecord（现有）

- `credit`: 可空数值；缺失时不计入合计。
- `isPassed`: 由现有成绩状态规则派生的布尔事实。
- `term`: 可空学期标识。
- `earnedCreditsForTerm(term)`: 选取指定学期（`null` 表示全部）且已通过的记录，对非空学分求和。空记录集返回 `0`；快照未加载时由视图区分未知态。

## InfoPrimarySource（视图状态）

- `all`
- `schoolWebsite`: 包括学校官网及教务处等官网子站。
- `wechat`: 包括微信公众号与服务号。

## InfoRefreshSnapshot（现有扩展）

- `kind`: 单渠道或全部启用渠道刷新。
- `status/progress/message`: 统一反映整个刷新任务。
- 状态转换：`idle -> running -> completed|failed -> idle`。
- 同一时刻只允许一个刷新任务；全部刷新任务内部覆盖每个已启用渠道。

## CourseScheduleBlock（现有视图映射）

- `weekday`: 星期列索引。
- `startUnit` / `endUnit`: 纵向起止节次，满足 `startUnit <= endUnit`。
- `title`, `location`, `teacher`, `startTime`: 课程块内容。
- 位置由星期列和节次计算，高度由包含的节次数决定。

## EmailMessageSnapshot（现有）

- 列表摘要：`receivedAt`、`subject`、`sender`。
- 详情：本机解析的 `body` 文本与现有附件元数据。
- 远端 HTML、图片、脚本和样式不参与渲染或请求。

## Navigation destination（现有）

- destination 索引保持不变。
- 设置仍为索引 6，但桌面渲染位置从主列表移至 footer。
- AI 服务仍为索引 7；移动端更多菜单保持既有映射。
