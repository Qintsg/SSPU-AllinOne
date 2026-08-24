# 培养计划

> 子模块：[EAMS 教务](README.md)　·　状态：**部分实现**（解析就绪，前端重构）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.program-plan` |
| 状态 | 部分实现 |
| 平台 | 全平台 |
| 关联 Issue | #174 |
| 主要代码 | `lib/services/academic_eams_overview_flow.dart`、`academic_eams_page_parser*.dart`；`lib/models/academic_eams/program_plan.dart` |

## 1. 需求

读取并展示培养计划（课程要求、学分构成）及完成情况（#174）。

**验收要点**
- 解析培养计划课程结构与学分要求 → `programPlan`。
- 结合已修成绩呈现完成情况 → `programCompletion`。

## 2. 实现

- 经 [EAMS 基座](foundation.md) overview 流程解析；快照含 `programPlan` 与 `programCompletion`。
- per-account 缓存（随 overview）。

## 3. 关联

- 依赖：[EAMS 基座](foundation.md)；完成度结合 [成绩查询](grade.md)。

## 4. 约束

- 只读；培养计划随专业/年级不同，解析需容错。

## 5. 待办与演进

- [ ] 前端重构后的培养计划页与完成度展示（#174）。
