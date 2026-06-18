# 日历

> 子模块：[EAMS 教务](README.md)　·　状态：**部分实现**（课表服务已实现；日历视图/考试叠加/导入导出设计中）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `academic.eams.calendar` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #175 |
| 主要代码 | `lib/services/academic_eams_page_parser_tables.dart`、`academic_eams_service.dart`（`fetchCourseTable`）；`lib/models/academic_eams/course_table.dart`、`course_period.dart` |

## 1. 需求

以**日历**形式统一展示**课程表**与**考试**的时间（原「课表」升级为日历），并支持**一键导入系统日历软件（若有）**或**导出日历文件（.ics，双端均支持）**。

**验收要点**
- 日历内同时呈现课程（按周次/星期/节次）与考试（按考试时间）。
- 支持当周视图与整学期视图；当周课程可在首页卡片呈现（#175）。
- **导出 .ics**：桌面与移动端均可导出标准 iCalendar 文件。
- **导入系统日历**：设备有系统日历软件时可一键导入；无则回退为导出文件。

## 2. 数据来源

- **课程**：经 [EAMS 基座](foundation.md) `fetchCourseTable`（scope=courseTableOnly）解析 → `AcademicEamsCourseTable`（含 `CoursePeriod` 节次定义）；当周/周次定位依赖 [校历](../../platform/academic-calendar.md)。
- **考试**：复用 [考试安排](exam-schedule.md) 的解析结果（考试时间/地点）叠加到日历。
- 课程数据 per-account 缓存（courseTable collection）。

## 3. 日历视图

- 日 / 周 / 月视图；课程按周次重复呈现，考试为单次事件，二者在同一日历区分样式。
- 课程节次时间结合 `CoursePeriod` 与校历周次换算为具体日期时间。

## 4. 导入 / 导出

| 能力 | 平台 | 说明 |
| --- | --- | --- |
| 导出 .ics 文件 | **双端均支持** | 生成标准 iCalendar：课程为按周次的重复/逐次事件，考试为单次事件；可分享/保存 |
| 导入系统日历（若有） | 有系统日历软件的平台 | 移动端经系统日历 API / 打开 .ics 交系统日历接管；桌面经 .ics 关联日历软件；**无日历软件则回退导出文件** |

- 导入/导出仅生成/移交事件，不回写教务系统（只读原则）。
- 事件内容不含敏感信息（仅课程名/时间/地点/考试）。

## 5. 关联

- 依赖：[EAMS 基座](foundation.md)、[校历](../../platform/academic-calendar.md)（学期/周次换算）、[考试安排](exam-schedule.md)（考试时间数据）。
- 被依赖：[主页仪表盘](../../platform/shell/home-dashboard.md)（当周课程卡片）、[通知与提醒](../../platform/system/notifications.md)（课程/考试提醒 #188）。

## 6. 约束

- 只读；不可定位学期/周次时降级展示（见校历）。
- 导入/导出为单向移交，不修改教务数据；.ics 事件不含敏感信息。

## 7. 待办与演进

- [ ] 日历视图（日/周/月）整合课程 + 考试时间（#175）。
- [ ] 导出 .ics（双端）与导入系统日历（若有，含回退）。
- [ ] 完善当周课程首页卡片；与 #188 提醒、#189 小组件对接。
