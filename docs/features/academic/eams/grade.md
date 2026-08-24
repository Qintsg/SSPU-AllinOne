# 成绩查询

> 子模块：[EAMS 教务](README.md)　·　状态：**部分实现**（解析就绪，前端重构）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.grade` |
| 状态 | 部分实现 |
| 平台 | 全平台 |
| 关联 Issue | #177 |
| 主要代码 | `lib/services/academic_eams_grade_flow.dart`、`academic_eams_service.dart`（`fetchGrades`）；`lib/models/academic_eams/*` |

## 1. 需求

一次性读取当前学期与历史成绩，前端按学年学期分组展示，不逐学期重复请求。

**验收要点**
- 解析课程名、成绩、学分、绩点、学年学期等。
- 按学年学期分组；提供学期切换与汇总（如均绩）。

## 2. 实现

- 经 [EAMS 基座](foundation.md) `fetchGrades`（scope=gradesOnly）一次拉取当前 + 历史成绩。
- 学期切换由前端按分组实现（不重复请求）。
- per-account 缓存（grade collection）。

## 3. 关联

- 依赖：[EAMS 基座](foundation.md)。
- 关联：[过程化成绩](grade-process.md)（同为成绩域，按学期补充平时明细）。

## 4. 约束

- 只读；成绩属敏感数据，缓存按账号隔离、不进日志。

## 5. 待办与演进

- [ ] 前端重构后的成绩卡片/详情/学期分组与汇总（#177）。
