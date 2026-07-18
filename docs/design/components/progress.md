# Progress 线性进度

> 任务/加载完成度的横条——已填青雾，配百分比。上传、学分修读、资料完整度。

## 概述

- **用途**：可量化进度（上传 64%、学分 78/120、资料完整度）。
- **变体**：determinate（确定百分比，默认）/ indeterminate（未知进度，往复动画）。
- **关键状态**：进行中 / 完成（100%）。

---

## 解剖 Anatomy

```
████████████░░░░░░░░  64%
↑已填 --brand-strong  ↑未填 --border  ↑百分比 mono
轨道高 8 · 圆角 full
```

**必需元素**：轨道（8px）、已填段（`--brand-strong`）。**可选**：尾随百分比（等宽）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **determinate** | 已填宽 = 百分比，宽度 300ms 过渡 |
| **indeterminate** | 一段在轨道内往复（未知进度） |
| **complete** | 100%（可转 `--success` 表"已完成"，可选） |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | brandStrong（已填） | `#478384` | `#5C9A9B` |
| `--border` | border（未填轨道） | `#D1CEC9` | `#353A3F` |

---

## Flutter API

```dart
class YhProgress extends StatelessWidget {
  const YhProgress({super.key, this.value, this.showPercent = true});
  final double? value;   // null = indeterminate
}
```

```dart
YhProgress(value: 0.64);
YhProgress(value: null);   // 未知进度
```

---

## Do & Don't

### ✅ Do
- 确定进度配百分比/分数文本，让数字可读。
- 轨道 ≥ 6px 便于辨识；用 Progress 表线性、Ring 表圆形。

### ❌ Don't
- 用 Progress 表示纯装饰（无真实进度）。
- 百分比文字与条不同步。

---

## 可交互样例

[`samples/progress.html`](./samples/progress.html)

## 无障碍 Accessibility

- `Semantics(value:'64%')` + `role=progressbar`；indeterminate 标注"加载中"。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
