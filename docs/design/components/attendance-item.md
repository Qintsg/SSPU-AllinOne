# AttendanceItem 考勤签到行

> 体育/活动考勤的单条签到——课程/活动名 + 时间地点 + 状态药丸 + 签到按钮。点一下完成签到。

## 概述

- **用途**：体育课打卡、第二课堂活动签到、晨跑记录。
- **变体**：pending（待签到，显示按钮）/ done（已签，显示状态 + 时间）/ missed（缺勤）。
- **关键状态**：pending / done / missed / closed（已过签到窗口）。

---

## 解剖 Anatomy

```
┌──────────────────────────────────────┐
│ 晨跑打卡                  ● 待签到 [签到] │  ← 名称 + 状态药丸 + 行动按钮
│ 6:30–7:30 · 田径场                      │
└──────────────────────────────────────┘
```

**必需元素**：名称、时间/地点、状态（StatusPill）。**可选**：签到按钮（pending 时）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **pending** | `info`/`warn` 药丸 + 「签到」primary 按钮 |
| **done** | `ok` 药丸「已签 7:02」+ 按钮消失 |
| **missed** | `err` 药丸「缺勤」 |
| **closed** | 灰药丸「已结束」+ 按钮禁用 |

---

## Token 映射

| 设计 token | 亮色 | 暗色 |
|---|---|---|
| `--surface` / `--border` | `#FFFFFF` / `#D1CEC9` | `#1E2226` / `#353A3F` |
| `--brand-strong`（签到按钮） | `#478384` | `#5C9A9B` |
| 状态色 | 见 StatusPill | 同 |

---

## Flutter API

```dart
enum YhAttendStatus { pending, done, missed, closed }

class YhAttendanceItem extends StatelessWidget {
  const YhAttendanceItem({super.key, required this.title, required this.meta, required this.status, this.checkedAt, this.onCheckIn});
}
```

```dart
YhAttendanceItem(title: '晨跑打卡', meta: '6:30–7:30 · 田径场', status: YhAttendStatus.pending, onCheckIn: checkIn);
YhAttendanceItem(title: '体育课', meta: '14:00 · 体育馆', status: YhAttendStatus.done, checkedAt: '14:02');
```

---

## Do & Don't

### ✅ Do
- 状态用 StatusPill 即时反映；签到成功后按钮变"已签 + 时间"。
- 签到窗口关闭后禁用按钮并说明原因。

### ❌ Don't
- 已签到还显示可点签到按钮（状态不一致）。
- 缺勤态不给说明（用户不知为何缺勤）。

---

## 可交互样例

[`samples/attendance-item.html`](./samples/attendance-item.html) — 点「签到」变已签。

## 无障碍 Accessibility

- 行 `Semantics(label:'晨跑打卡，6:30 到 7:30，田径场，待签到')`；签到成功 `liveRegion` 播报"已签到 7:02"。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
