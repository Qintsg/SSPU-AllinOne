# Stepper 步进器

> 小整数的增减控件——数量、份数、人数。− / 值 / + 三段，到边界自动禁用。

## 概述

- **用途**：小范围整数增减（购买份数 1–10、人数、节数）。
- **变体**：单一变体（横向 − 值 +）。
- **关键状态**：值变化 / 到 min 禁用减 / 到 max 禁用加 / 整体 disabled。

---

## 解剖 Anatomy

```
╭────┬──────┬────╮
│ −  │  2   │ +  │   ← 边框整体圈定，值居中等宽数字 mono
╰────┴──────┴────╯
 40×40  48宽  40×40
```

**必需元素**：减按钮、值显示（等宽 mono）、加按钮；整体描边圆角 10。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | 加减青雾字，值黑字 |
| **hover** | 加 / 减按钮浅青雾底 |
| **at min** | 减按钮变弱化色 + 禁用 |
| **at max** | 加按钮变弱化色 + 禁用 |
| **disabled** | 整体不透明度 40% |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--brand-tint` | `brandTint` | `0xFFE9F0F0` | `0xFF1E3233` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |
| `--muted` | `muted`（禁用色） | `0xFF6B6964` | `0xFF9A9893` |

---

## Flutter API

```dart
class YhStepper extends StatelessWidget {
  const YhStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0, this.max = 99, this.step = 1,
    this.disabled = false,
  });
}
```

```dart
YhStepper(value: qty, min: 1, max: 10, onChanged: (v) => setState(() => qty = v));
```

---

## Do & Don't

### ✅ Do
- 范围小（≤ ~20）用 Stepper；范围大改输入框 + Slider。
- 到边界禁用对应按钮，给出明确反馈。
- 值用等宽数字，避免位数变化时宽度跳动。

### ❌ Don't
- 大范围（如 0–1000）用 Stepper（点到手酸）。
- 允许越界（必须 clamp 到 min/max）。

---

## 可交互样例

[`samples/stepper.html`](./samples/stepper.html)

## 无障碍 Accessibility

- 加减按钮各带 `Semantics(button:true, label:'增加'/'减少')`；值区 `liveRegion: true` 播报变化。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
