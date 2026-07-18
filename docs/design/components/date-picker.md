# DatePicker 日期选择

> 日历浮层选日期——月份头（上下月切换）、星期行、日期网格。今天描青雾环，选中填青雾实心。

## 概述

- **用途**：选单个日期（请假日期、截止日、查询日）。区间选择是其扩展（双端点 + 连段高亮）。
- **变体**：single（单日，默认）/ range（区间，扩展）。
- **关键状态**：default / today / selected / muted（非本月）/ disabled（不可选日）。

---

## 解剖 Anatomy

```
┌───────────────────────────┐
│  ‹     2026 年 6 月     ›   │  ← 月份头：上下月按钮 + 月份标题
├───────────────────────────┤
│ 日 一 二 三 四 五 六        │  ← 星期行（--muted）
│ 31  1  2  3  4  5  6        │  ← 非本月日 mute
│  …            17 …          │  ← 今天：青雾环
│ 21 …                        │  ← 选中：青雾实心 + 白字
└───────────────────────────┘
```

**必需元素**：月份头、星期行（7 列）、日期网格（`grid-template-columns:repeat(7,1fr)`，格子 `aspect-ratio:1`）。

---

## 状态 States（日格）

| 状态 | 视觉 |
|---|---|
| **default** | `--fg` 等宽数字 |
| **hover** | `--brand-tint` 浅底 |
| **today** | `inset 0 0 0 1.5px --brand`（青雾环） |
| **selected** | `--brand-strong` 实心 + `--on-brand` 字 |
| **muted** | 非本月，`opacity:0.35` |
| **disabled** | 不可选日，`--muted` + 划线/降透明 |

> 选中 + 今天同一天：去掉环、保留实心（`.sel.today` 无 box-shadow）。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand` | `brandPrimary`（今天环） | `0xFF6FA3A4` | `0xFF7FB0B1` |
| `--brand-strong` | `brandStrong`（选中底） | `0xFF478384` | `0xFF5C9A9B` |
| `--brand-tint` | `brandTint`（hover） | `0xFFE9F0F0` | `0xFF1E3233` |
| `--on-brand` | `onBrand` | `0xFFFFFFFF` | `0xFF0A0D12` |
| `--surface` | `surface` | `0xFFFFFFFF` | `0xFF1E2226` |

---

## Flutter API

```dart
class YhDatePicker extends StatelessWidget {
  const YhDatePicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.firstDate, this.lastDate,
    this.disabledDates = const [],
  });
  // 自绘日历：Column(月份头, 星期行, GridView 7列)；
  // 通常配 YhSelect 风格触发器，点击弹出本浮层。
}
```

```dart
YhDatePicker(selected: date, onChanged: (d) => setState(() => date = d));
```

---

## Do & Don't

### ✅ Do
- 今天用环、选中用实心，两者视觉可区分。
- 非本月日 mute 但仍可点（切到对应月）。
- 数字用等宽（`--mono`），换月不跳动。

### ❌ Don't
- 今天和选中用同一种实心（无法区分"今天"与"已选"）。
- 不可选日仍可点击却无反馈。

---

## 可交互样例

[`samples/date-picker.html`](./samples/date-picker.html) — 2026 年 6 月，今天 17 日描环、21 日选中。

## 无障碍 Accessibility

- 每个日格 `Semantics(button:true, selected:..., label:'6月17日 周三 今天')`；方向键在网格移动，PageUp/Down 翻月。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
