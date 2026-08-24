# 开课查询

> 子模块：[EAMS 教务](README.md)　·　状态：**部分实现**（搜索服务已实现，前端重构）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.course-offerings` |
| 状态 | 部分实现 |
| 平台 | 全平台 |
| 关联 Issue | #179 |
| 主要代码 | `lib/services/academic_eams_search_flow.dart`、`academic_eams_service.dart`（`searchCourseOfferings`）、`academic_eams_page_parser_forms.dart`；`lib/models/academic_eams/course_offerings.dart` |

## 1. 需求

只读查询开课列表（按学期/课程/教师/院系等条件检索），**不提供选课、退课、调课入口**（#179）。

**验收要点**
- 解析开课查询表单并按 `AcademicCourseOfferingSearchCriteria` 构造安全查询参数。
- 解析结果列表；无命中返回 `partialSuccess` 并提示。

## 2. 实现

- 经 [EAMS 基座](foundation.md) `searchCourseOfferings(criteria)`：发现入口 → 解析查询表单 → `submitForm`（仅查询）→ 解析 `AcademicCourseOfferings`。
- 入口/表单不可识别 → `readOnlyEntryUnavailable` / `queryFormUnavailable`。

## 3. 关联

- 依赖：[EAMS 基座](foundation.md)（入口发现 + 只读表单提交）。

## 4. 约束

- **严格只读**：仅提交查询型表单，不执行选课/退课/调课等任何写操作。

## 5. 待办与演进

- [ ] 前端重构后的开课查询页与卡片（#179）。
- [ ] 查询条件表单的健壮解析。
