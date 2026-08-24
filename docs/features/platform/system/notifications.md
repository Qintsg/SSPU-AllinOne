# 通知与提醒

> 子模块：[系统能力](README.md)　·　状态：**部分实现**（开关/勿扰已实现，提醒/推送投递设计中）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.system.notifications` |
| 状态 | 部分实现 |
| 平台 | 全平台（投递依平台能力） |
| 关联 Issue | #188 |
| 主要代码 | `lib/services/notification_service.dart`、`tray_service.dart`；`message_state_service*.dart`（开关/勿扰配置） |

## 1. 需求

统一通知投递与提醒（#188）：课程/考试提醒、新消息推送，受全局开关与勿扰时段约束。**info 只产消息并声明通知意愿，投递在此实现**。

**验收要点**
- 基于课表/考试的本地定时**课程/考试提醒**。
- **新消息推送**：消费 [消息中心](../../info/message-center.md) 的新消息与单源（含单公众号）通知意愿。
- **勿扰时段**：DnD 时间段内不打扰；全局推送开关。

## 2. 范围（本期）

| 能力 | 是否纳入 | 说明 |
| --- | --- | --- |
| 课程/考试提醒 | ✅ | 基于 [日历](../../academic/eams/calendar.md)/[考试](../../academic/eams/exam-schedule.md) 的本地定时提醒 |
| 新消息推送 | ✅ | 消费消息中心新消息 + 通知意愿 |
| 勿扰时段 | ✅ | DnD 时间段（现有配置） |
| 全局开关 | ✅ | 通知总开关 |
| 逐源/单公众号开关 | 由 info 声明意愿 | 开关意愿在 info，投递在此尊重 |

## 3. 实现

- `notification_service`：本地通知调度与展示；`tray_service`：桌面托盘。
- 提醒：读 [校历](../academic-calendar.md) 学期/周次 + 课表/考试时间，计算本地定时通知。
- 推送：消息中心产新消息 → 校验全局开关/勿扰/单源意愿 → 投递。
- 配置（全局开关、DnD、单公众号意愿）现存于 `message_state_service`；归 [设置中心](../shell/settings.md) 呈现。

## 4. 关联

- 依赖：[消息中心](../../info/message-center.md)（消息与通知意愿）、[日历](../../academic/eams/calendar.md)、[考试安排](../../academic/eams/exam-schedule.md)、[校历](../academic-calendar.md)、[设置中心](../shell/settings.md)。
- 平台差异：移动端系统通知、桌面托盘/系统通知能力不同。

## 5. 约束

- 投递受全局开关与勿扰约束；尊重 info 的单源通知意愿。
- 通知内容不含敏感明文；不在启动时无条件推送。

## 6. 待办与演进

- [ ] 课程/考试本地定时提醒（#188）。
- [ ] 新消息推送投递链路与意愿对接。
- [ ] 勿扰/全局开关与设置页协同；移动/桌面投递适配。
