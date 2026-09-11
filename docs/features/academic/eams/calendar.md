# 日历

> 子模块：[EAMS 教务](README.md)　·　状态：**本地实现已完成**（课程/考试本周与整学期议程、ICS 导出及系统关联应用导入；主流日历应用实机验收待补）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.calendar` |
| 状态 | 本地代码与自动化测试已完成；系统日历关联应用实机验收待补 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #175（课表部分已关闭）；课程/考试整合与导入导出暂无独立 Issue |
| 主要代码 | `lib/pages/course_schedule_page.dart`、`course_schedule_views.dart`；`lib/services/academic_eams_page_parser_tables.dart`、`academic_eams_service.dart`、`academic_ics_export_service.dart`；`lib/models/academic_eams/course_table.dart`、`course_period.dart` |

## 1. 需求

以**日历**形式统一展示**课程表**与**考试**的时间（原「课表」升级为日历），并支持**一键导入系统日历软件（若有）**或**导出日历文件（.ics，双端均支持）**。

**验收要点**
- 日历内同时呈现课程（按周次/星期/节次）与考试（按考试时间）。
- 支持当周视图与整学期视图；当周课程可在首页卡片呈现（#175）。
- **导出 .ics**：桌面与移动端均可导出符合 RFC 5545 的 iCalendar 文件；事件使用 `Asia/Shanghai` 时区和可移植 `VTIMEZONE` 定义，长行按 UTF-8 八位字节折叠。
- **导入系统日历**：设备有系统日历软件时可一键导入；无则回退为导出文件。

## 2. 数据来源

- **课程**：经 [EAMS 基座](foundation.md) `fetchCourseTable`（scope=courseTableOnly）解析 → `AcademicEamsCourseTable`（含 `CoursePeriod` 节次定义）；当周/周次定位依赖 [校历](../../platform/academic-calendar.md)。
- **考试**：复用 [考试安排](exam-schedule.md) 的解析结果（考试时间/地点）叠加到日历。
- 课程数据 per-account 缓存（courseTable collection）。

## 3. 日历视图

- 课程表页可切换“课程与考试”，提供本周与整学期议程；课程按周次重复呈现，考试为单次事件，并以类型标签区分。
- 课程节次时间结合 `CoursePeriod` 与校历周次换算为具体日期时间。

## 4. 导入 / 导出

| 能力 | 平台 | 说明 |
| --- | --- | --- |
| 导出 .ics 文件 | **双端均支持** | 生成标准 iCalendar：课程按周次展开为逐次事件，考试为单次事件；保存后交给系统打开 |
| 导入系统日历（若有） | **双端均支持** | 导出后通过系统打开 `.ics` 交给已安装的日历应用；无关联应用时保留文件路径供用户手动导入 |

- 导入/导出仅生成/移交事件，不回写教务系统（只读原则）。
- 事件内容不含敏感信息（仅课程名/时间/地点/考试）。考试缺少完整时间范围时不会生成猜测事件；不会默认填充 09:00 或固定时长。

## 5. 关联

- 依赖：[EAMS 基座](foundation.md)、[校历](../../platform/academic-calendar.md)（学期/周次换算）、[考试安排](exam-schedule.md)（考试时间数据）。
- 被依赖：[主页仪表盘](../../platform/shell/home-dashboard.md)（当周课程卡片）、[通知与提醒](../../platform/system/notifications.md)（课程/考试提醒 #188）。

## 6. 约束

- 只读；不可定位学期/周次时降级展示（见校历）。
- 导入/导出为单向移交，不修改教务数据；.ics 事件不含敏感信息。

## 7. 待办与演进

- [x] 本周与整学期议程整合课程 + 考试时间。
- [x] 导出 .ics（双端）并通过系统关联应用打开。
- [x] ICS 使用 `TZID=Asia/Shanghai`、`VTIMEZONE`、上海墙上时间、原始考试开始/结束时间和 RFC 5545 UTF-8 折行；缺少完整考试时间时跳过该事件。
- [ ] **后续增强**：月历网格与平台原生日历 API（当前标准 `.ics` 导入链路已可用）。
- [ ] **平台验收**：在各目标系统的关联日历应用中核对事件数量、时间、标题和地点。
- [x] 当周课程首页卡片与 #188 本地提醒链路已接入课程数据；#188 仍待真实设备到点投递验证，#189 系统小组件尚未实现。
