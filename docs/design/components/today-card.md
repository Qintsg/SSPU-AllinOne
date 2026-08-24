# TodayCard 今日卡

> 首页顶部的"今天概览"——日期 + 当天日程（课程/待办/提醒）的紧凑时间线。打开 App 第一眼看的就是它。

## 概述

- **用途**：首页今日聚合（今天有几节课、几个待办、天气提示）。
- **变体**：agenda（时间线日程，默认）/ empty（今日无安排，见 EmptyState）。
- **关键状态**：有日程 / 空。

---

## 解剖 Anatomy

```
┌──────────────────────────────┐
│ 6月17日 周三        3 节课 · 2 待办 │  ← 头：日期 + 概览 meta
├──────────────────────────────┤
│ 14:00  数据结构                 │  ← 时间线行：时间(mono) + 课程/事项
│        教三-401                 │
├──────────────────────────────┤
│ 16:00  高等数学作业截止          │
└──────────────────────────────┘
```

**必需元素**：日期头 + 概览统计；时间线行（时间 mono + 主次文）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **有日程** | 按时间排序的行列表 |
| **空** | 内嵌 EmptyState（"今天没有安排，好好休息"） |

---

## Token 映射

| 设计 token | 亮色 | 暗色 |
|---|---|---|
| `--surface` / `--border` | `#FFFFFF` / `#D1CEC9` | `#1E2226` / `#353A3F` |
| `--brand-strong`（时间） | `#478384` | `#5C9A9B` |
| `--mono`（时间） | 系统等宽字体栈 | 同 |

---

## Flutter API

```dart
class YhTodayCard extends StatelessWidget {
  const YhTodayCard({super.key, required this.date, required this.items});
  // items: List<({String time, String title, String? subtitle})>
}
```

```dart
YhTodayCard(date: DateTime.now(), items: [
  (time: '14:00', title: '数据结构', subtitle: '教三-401'),
  (time: '16:00', title: '高等数学作业截止', subtitle: null),
]);
```

---

## Do & Don't

### ✅ Do
- 按时间正序；时间用等宽对齐。
- 概览 meta 用一句话点明今日负荷（"3 节课 · 2 待办"）。

### ❌ Don't
- 把整周课程塞进今日卡（只放"今天"）。
- 空态留白无引导（用 EmptyState 给一句话）。

---

## 可交互样例

[`samples/today-card.html`](./samples/today-card.html)

## 无障碍 Accessibility

- 卡片 `Semantics(header:'今日 6月17日 周三')`；每行报"14:00 数据结构 教三-401"。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
