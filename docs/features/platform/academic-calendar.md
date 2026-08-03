# 校历

> 模块：[平台基础](README.md)　·　状态：**已实现**（五平台全量视觉仍随清源总体验收）
>
> 由教务上移为**通用能力**：无需登录/门禁，供全局学期与周次计算。

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.academic-calendar` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | — |
| 主要代码 | `lib/services/academic_calendar_service.dart`、`academic_calendar_file_ops*.dart`、`academic_term_service.dart`；`lib/pages/academic_calendar_*.dart`；`lib/models/academic_calendar.dart`、`academic_term.dart` |

## 1. 需求

提供校历查询与**学期/周次计算**，作为课表、考试、过程化成绩等功能的时间上下文基座。

**验收要点**
- 展示教务处 2021 年以后的校历缓存、结构化学期范围、夏季教学段、特殊日期说明与原始 PDF。
- 计算当前日期所在学期与周数；支持「查询使用学期」与「当前实际学期」分别标注。
- 无需校园网 / VPN。

## 2. 实现

- 来源：`https://jwc.sspu.edu.cn/xl/list.htm`，**公开、无需登录/门禁**。
- 优先读取本地缓存；缺少当前学年或 7/8 月临近下一学年时自动抓取。
- PDF 与抽取文本缓存于系统默认应用数据目录下的 `academic_calendars/pdf/` 与 `academic_calendars/text/`（见 [本地存储](system/storage-sync.md)）。
- `academic_term_service`：当前学期与周数按校历缓存优先、内置官网校历兜底、按周一自动计算；夏季学期按逐年教学段定位，空档区分暑假/寒假；超出可定位范围时提示「暂无日期定位」。

## 3. 交互与界面（期望行为，前端重构后落地）

- 校历入口：学期范围、夏季教学段、特殊日期、原始 PDF 查看。
- 学期设置：统一选择后续查询使用的学期；展示当前实际学期 + 单独标明「查询使用」学期。

## 4. 关联

- 被依赖：[日历](../academic/eams/calendar.md)、[考试安排](../academic/eams/exam-schedule.md)、[过程化成绩](../academic/eams/grade-process.md)、[空闲教室](../academic/eams/free-classrooms.md) 等的学期/周次上下文。
- 依赖：[本地存储](system/storage-sync.md)（PDF/文本缓存）。

## 5. 约束

- 公开数据、无需登录/门禁；PDF 与文本缓存于系统默认应用数据目录。
- 不可定位学期/周次时，相关详情页按不可定位状态降级。

## 6. 待办与演进

- [x] 前端重构后的校历查看（含原始 PDF）与学期设置。
