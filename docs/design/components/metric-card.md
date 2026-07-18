# MetricCard 指标卡

> 单个关键数字的展示卡——标签 + 大号等宽数值 + 趋势变化。校园卡余额、待办数、出勤率。

## 概述

- **用途**：仪表盘/首页的关键指标（余额、未读、出勤率）。
- **变体**：plain（数值）/ with-trend（带涨跌）/ with-icon（标签前图标）。
- **关键状态**：静态；趋势 up（绿）/ down（红）。

---

## 解剖 Anatomy

```
┌──────────────────┐
│ 💳 校园卡余额      │  ← 标签 lab（可带图标）
│ ¥128.50          │  ← 数值 v（等宽 mono 26px）
│ ↑ 本月 +¥40       │  ← 趋势 d（up 绿 / down 红）
└──────────────────┘
```

**必需元素**：标签、数值（等宽）。**可选**：趋势、前置图标。

---

## 状态 States

| 趋势 | 视觉 |
|---|---|
| **up** | `--success` + ↑ |
| **down** | `--danger` + ↓ |
| **flat** | `--muted`，无箭头 |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--surface` | surface | `#FFFFFF` | `#1E2226` |
| `--mono` | fontFamilyMono（数值） | JetBrains Mono | 同 |
| `--success` / `--danger` | success / danger | `#1F8F57` / `#C23B33` | `#28C26B` / `#E5564B` |

> 数值必用等宽 `--mono` + `tabular-nums`，多卡并排时小数点对齐。

---

## Flutter API

```dart
class YhMetricCard extends StatelessWidget {
  const YhMetricCard({super.key, required this.label, required this.value, this.delta, this.deltaUp = true, this.icon});
}
```

```dart
YhMetricCard(label: '校园卡余额', value: '¥128.50', delta: '本月 +¥40', deltaUp: true, icon: Icons.credit_card);
```

---

## Do & Don't

### ✅ Do
- 数值等宽对齐；趋势用色 + 箭头双编码。
- 一卡一指标，标题点明口径（"本月""本周"）。

### ❌ Don't
- 一卡塞多个数字（拆成多卡）。
- 趋势只用颜色不用箭头（色盲不友好）。

---

## 可交互样例

[`samples/metric-card.html`](./samples/metric-card.html)

## 无障碍 Accessibility

- `Semantics(label:'校园卡余额 128.50 元，本月增加 40 元')`；趋势方向用文字而非仅颜色。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
