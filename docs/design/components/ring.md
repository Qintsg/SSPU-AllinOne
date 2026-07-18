# Ring 环形进度

> 圆形的完成度指示——青雾扇区 + 中心百分比。比线性更省横向空间，适合指标卡角落、宫格。

## 概述

- **用途**：紧凑的圆形进度（学分完成度、电量、目标达成）。
- **变体**：仅 determinate；尺寸可调（默认 64）。
- **关键状态**：进行中 / 完成。

---

## 解剖 Anatomy

```
   ╭───╮
  │ 72% │   ← conic-gradient 扇区（青雾已完成 / 灰未完成）+ 中心镂空显数值
   ╰───╯
```

**必需元素**：环（`conic-gradient(--brand-strong <pct>%, --border 0)`）、中心圆（`--surface` 镂空）、中心数值（等宽）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **进行中** | 扇区到当前百分比 |
| **完成** | 整环青雾（可转 `--success`，可选） |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | brandStrong（扇区） | `#478384` | `#5C9A9B` |
| `--border` | border（未完成扇区） | `#D1CEC9` | `#353A3F` |
| `--surface` | surface（中心镂空） | `#FFFFFF` | `#1E2226` |

---

## Flutter API

```dart
class YhRing extends StatelessWidget {
  const YhRing({super.key, required this.value, this.size = 64, this.label});
  // CustomPaint 画弧：sweepAngle = value * 2π；中心显 label 或百分比。
}
```

```dart
YhRing(value: 0.72);                 // 显示 72%
YhRing(value: 0.9, label: '9/10');   // 自定义中心文案
```

---

## Do & Don't

### ✅ Do
- 中心放百分比或分数，一目了然。
- 小空间（卡角、宫格）优先 Ring，宽行用 Progress。

### ❌ Don't
- 环太细导致扇区难辨。
- 同屏混用 Ring/Progress 表示同类进度（风格不统一）。

---

## 可交互样例

[`samples/ring.html`](./samples/ring.html)

## 无障碍 Accessibility

- `Semantics(value:'72%')` + `role=progressbar`；中心数值可被读屏读取。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
