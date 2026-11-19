# 培养计划

> 子模块：[EAMS 教务](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.program-plan` |
| 状态 | 已实现 |
| 平台 | 全平台 |
| 关联 Issue | #174、#353 |
| 主要代码 | `lib/pages/academic_program_plan_page.dart`；`lib/services/academic_portal_queries.dart`、`lib/services/academic_portal_parsers.dart`；`lib/models/academic_eams/program_plan.dart` |

## 1. 需求

读取并展示培养计划（课程要求、学分构成）及完成情况（#174）。

**验收要点**
- 解析培养计划课程结构与学分要求 → `programPlan`。
- 结合已修成绩呈现完成情况 → `programCompletion`。

## 2. 实现

- 经[教务基座](foundation.md)读取新版教务的我的培养方案，展示方案名称、课程模块、课程性质、学分及建议修读学期。
- 方案和学分进度随教务概览按账号缓存。
- 独立详情页支持按模块筛选课程。学分和课程完成进度根据已公布成绩估算，毕业要求以教务系统为准。
- 课程要求为空时展示明确空态与“重新读取”；模块进度在窄屏纵向排列，避免摘要被截断。
- 成功、空结果、登录失效和网络失败均有可恢复状态；刷新失败不会把已有有效方案误替换成空白页。

## 3. 关联

- 依赖：[EAMS 基座](foundation.md)；完成度结合 [成绩查询](grade.md)。

## 4. 约束

- 只读；培养计划随专业/年级不同，解析需容错。

## 5. 待办与演进

- [x] 首页培养方案完成度摘要。
- [x] 清源培养方案详情页、模块进度与课程浏览（#174）。
- [x] 空结果、登录失效、网络失败、重试和 360px 窄屏布局状态。
