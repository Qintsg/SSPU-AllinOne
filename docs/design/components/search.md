# Search 搜索框

> TextField 的搜索特化变体——浅底胶囊、无边框、前置放大镜，尾随清除。前置图标与文本竖向居中、绝不重合。

## 概述

- **用途**：列表 / 页面顶部的即时搜索入口。
- **变体**：inline（页内浅底胶囊）/ bar（顶栏整条）。
- **关键状态**：empty / focus / filled（显示清除 ×）/ disabled。

---

## 解剖 Anatomy

```
╭───────────────────────────────────╮
│ ⌕ 10  搜索课程、通知、同学…   10 ⊗ │  ← 控件行 flex align-items:center
╰───────────────────────────────────╯
  ↑前置放大镜      ↑占位符可见      ↑尾随清除（filled 时）
```

**布局契约**：与 TextField 一致——前置图标、input、尾随 × 都是控件行 flex 同级，竖向居中、不重合。占位符用 `--muted`（**不可透明**，否则文字消失）。

---

## 变体 Variants

| 变体 | 视觉 | token |
|---|---|---|
| **inline** | `--sunken` 浅底 + 无边框 + 圆角 full | 页内卡片中 |
| **bar** | 同上，宽度撑满顶栏 | AppBar 搜索态 |

聚焦时：底色转 `--surface` + 描边 `--brand-strong`，前置图标转青雾。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **empty** | 浅底 + 放大镜 + `--muted` 占位符 |
| **focus** | 白底 + 青雾边框 + 青雾放大镜 |
| **filled** | 显示尾随清除 ×，点击清空并保持聚焦 |
| **disabled** | 不透明度 45% |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--sunken` | `sunken` | `0xFFFAFAFA` | `0xFF181B1E` |
| `--surface` | `surface` | `0xFFFFFFFF` | `0xFF1E2226` |
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--muted` | `muted` | `0xFF6B6964` | `0xFF9A9893` |
| `--radius-full` | `radiusFull` | `999` | `999` |

---

## Flutter API

```dart
class YhSearchField extends StatelessWidget {
  const YhSearchField({
    super.key,
    this.controller,
    this.hint = '搜索',
    this.onChanged,
    this.onClear,
    this.enabled = true,
  });
  // 复用 YhTextField 外壳：variant=search → 浅底胶囊；filled 时显示清除按钮。
}
```

```dart
YhSearchField(hint: '搜索课程、通知、同学…', onChanged: doSearch, onClear: reset);
```

---

## Do & Don't

### ✅ Do
- 占位符写清楚搜索范围（"搜索课程、通知、同学"）。
- 有内容才显示清除 ×；点击后清空并保持聚焦。
- 前置图标固定 20×20、与文本 10px 间距。

### ❌ Don't
- 占位符设透明（文字消失）。
- 前置图标用绝对定位压住文本（重合）。
- 搜索框配独立"搜索"按钮——应输入即搜或回车搜。

---

## 可交互样例

[`samples/search.html`](./samples/search.html) — empty / filled（带清除）/ focus，亮暗双主题。

## 无障碍 Accessibility

- `Semantics(textField:true, label:'搜索')`；清除 × 单独 `label:'清除'`，触控区 ≥ 48dp。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 · 前置图标/文本竖向居中不重合 |
