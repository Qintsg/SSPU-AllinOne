# 过程化成绩

> 子模块：[EAMS 教务](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.grade-process` |
| 状态 | 已实现 |
| 平台 | 全平台 |
| 关联 Issue | #177 |
| 主要代码 | `lib/services/academic_eams_grade_flow.dart`、`academic_eams_service.dart`（`fetchGradeProcess`）；`lib/models/academic_eams/*` |

## 1. 需求

读取指定学期的过程化成绩（平时成绩明细），作为成绩的补充。

**验收要点**
- 从新版成绩单读取各课程已公布的分项成绩与占比。
- 在应用中按实际可选学期查看分项。

## 2. 实现

- `fetchGradeProcess({term, semester})` 复用新版成绩查询的分项数据，并按选择的学期过滤。
- per-account 缓存（gradeProcess collection）。

## 3. 关联

- 依赖：[EAMS 基座](foundation.md)、[校历](../../platform/academic-calendar.md)（学期选择）。
- 关联：[成绩查询](grade.md)。

## 4. 约束

- 只读，缓存按账号隔离。

## 5. 待办与演进

- [x] 清源过程化成绩页、课程明细与学期切换（#177）。
