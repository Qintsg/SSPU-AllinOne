# 个人信息

> 子模块：[EAMS 教务](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.profile` |
| 状态 | 已实现 |
| 平台 | 全平台 |
| 关联 Issue | #353 |
| 主要代码 | `lib/services/academic_student_profile_parser.dart`、`academic_eams_overview_flow.dart`；`lib/models/academic_eams/profile.dart` |

## 1. 需求

读取并展示学籍个人信息（姓名、学号、学院、专业、班级等首页摘要），作为教务首屏与其它功能的上下文。

## 2. 实现

- `refreshStudentProfileIfIncomplete` 复用统一身份认证会话，读取新版教务的 `/student/for-std/student-info`，将学籍详情映射为 `AcademicEamsProfile`。
- 学籍信息按账号保存在**加密缓存**中。保存前校验响应学号与当前账号一致。

## 3. 关联

- 依赖：[EAMS 基座](foundation.md)、[登录与凭据](../auth-credentials.md)（加密学籍缓存）。
- 被依赖：教务首屏与各功能上下文；[主页仪表盘](../../platform/shell/home-dashboard.md)（学生信息卡片）。

## 4. 约束

- 只读；学籍信息属敏感个人数据，加密缓存、不进日志。

## 5. 待办与演进

- [x] 清源教务总览中的个人信息展示、加密缓存恢复与静默刷新。
