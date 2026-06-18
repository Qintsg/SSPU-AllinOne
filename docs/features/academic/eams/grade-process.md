# 过程化成绩

> 子模块：[EAMS 教务](README.md)　·　状态：**部分实现**（解析就绪，前端重构）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.grade-process` |
| 状态 | 部分实现 |
| 平台 | 全平台 |
| 关联 Issue | #177 |
| 主要代码 | `lib/services/academic_eams_grade_flow.dart`、`academic_eams_service.dart`（`fetchGradeProcess`）；`lib/models/academic_eams/*` |

## 1. 需求

读取指定学期的过程化成绩（平时成绩明细），作为成绩的补充。

**验收要点**
- 按学期独立请求（EAMS 中过程化为分学期页面）。
- 解析各课程的平时成绩构成明细。

## 2. 实现

- 经 [EAMS 基座](foundation.md) `fetchGradeProcess({term, semester})`（scope=gradeProcessOnly）逐学期查询。
- per-account 缓存（gradeProcess collection）。

## 3. 关联

- 依赖：[EAMS 基座](foundation.md)、[校历](../../platform/academic-calendar.md)（学期选择）。
- 关联：[成绩查询](grade.md)。

## 4. 约束

- 只读；逐学期请求，敏感数据缓存按账号隔离。

## 5. 待办与演进

- [ ] 前端重构后的过程化成绩页与学期切换（#177）。
