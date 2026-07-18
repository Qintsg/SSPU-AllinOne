# Slider 滑块

> 连续 / 分档数值的拖动选择——音量、亮度、字号、价格区间。轨道填充与滑柄用青雾响应色。

## 概述

- **用途**：连续区间取值（亮度 0–100）或分档取值（字号 S/M/L）。
- **变体**：continuous（连续）/ discrete（带刻度档位）。
- **关键状态**：rest / dragging / disabled。

---

## 解剖 Anatomy

```
 ●━━━━━━━━━━○─────────────  ← 已填轨道 --brand-strong + 滑柄；未填轨道 --border
 ↑滑柄 20    ↑当前值
```

**必需元素**：轨道（4px 高）、已填部分（`--brand-strong`）、滑柄（青雾圆，拖动放大）。
**可选**：当前值气泡、两端 min/max 标签、discrete 刻度点。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | 已填青雾 + 灰未填 + 滑柄 |
| **hover** | 滑柄外环淡青雾光圈 |
| **dragging** | 滑柄放大 + 可选值气泡 |
| **disabled** | 不透明度 40% |

> Web 样例用原生 `<input type="range">` + `accent-color: var(--brand-strong)`，行为/无障碍即开即用。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--border` | `border`（未填轨道） | `0xFFD1CEC9` | `0xFF353A3F` |

---

## Flutter API

```dart
class YhSlider extends StatelessWidget {
  const YhSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0, this.max = 100,
    this.divisions,             // 非空 = discrete 档位
    this.disabled = false,
  });
}
```

```dart
YhSlider(value: brightness, onChanged: (v) => setState(() => brightness = v));
YhSlider(value: fontStep.toDouble(), min: 0, max: 2, divisions: 2, onChanged: ...); // S/M/L
```

---

## Do & Don't

### ✅ Do
- 精确数值同时给数字输入（Slider 粗调 + 输入框精调）。
- discrete 档位 ≤ 6，否则用 continuous。

### ❌ Don't
- 用 Slider 取需要精确数字的关键值（如金额）而不配输入框。
- 轨道太细（< 4px）导致难以点中。

---

## 可交互样例

[`samples/slider.html`](./samples/slider.html)

## 无障碍 Accessibility

- 原生 range 自带 `role="slider"` + 方向键调节；Flutter 用 `Semantics(slider: true, value: '$pct%')`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
