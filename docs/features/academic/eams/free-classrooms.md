# 空闲教室查询

> 子模块：[EAMS 教务](README.md)　·　状态：**部分实现**（搜索服务已实现，前端重构）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.free-classrooms` |
| 状态 | 部分实现 |
| 平台 | 全平台 |
| 关联 Issue | #176 |
| 主要代码 | `lib/services/academic_eams_search_flow.dart`、`academic_eams_service.dart`（`searchFreeClassrooms`）、`academic_eams_page_parser_forms.dart`；`lib/models/academic_eams/free_classrooms.dart` |

## 1. 需求

只读查询空闲教室（按校区/日期/节次等条件），**不提供预约或占用入口**（#176）。

**验收要点**
- 解析空闲教室查询表单并按 `AcademicFreeClassroomSearchCriteria` 构造安全查询参数。
- 解析空闲教室列表；无命中返回 `partialSuccess` 并提示。

## 2. 实现

- 经 [EAMS 基座](foundation.md) `searchFreeClassrooms(criteria)`：发现入口 → 解析查询表单 → `submitForm`（仅查询）→ 解析 `AcademicFreeClassrooms`。

## 3. 关联

- 依赖：[EAMS 基座](foundation.md)（入口发现 + 只读表单提交）、[校历](../../platform/academic-calendar.md)（日期/学期上下文）。

## 4. 约束

- **严格只读**：仅查询，不提供预约/占用等写操作。

## 5. 待办与演进

- [ ] 前端重构后的空闲教室查询页与卡片（#176）。
