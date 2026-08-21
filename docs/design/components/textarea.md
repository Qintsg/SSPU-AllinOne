# Textarea 多行文本框

> 多行文本录入——反馈、备注、留言。控件行顶部对齐，可配字数计数与上限。

## 概述

- **用途**：较长文本录入（意见反馈、备注、留言）。
- **变体**：fixed（固定行高）/ auto-grow（随内容增高，可选）。
- **关键状态**：rest / focus / filled / error / disabled。

---

## 解剖 Anatomy

```
意见反馈                         ← 标签 flabel
┌─────────────────────────────┐
│ 说说你的想法…                 │  ← 控件行 align-items:stretch
│                              │     textarea 顶部对齐、多行
└─────────────────────────────┘
0 / 200            请文明发言     ← helper：右浮计数 + 左侧提示
```

**布局契约**：复用 `.yh-field`，控件行改 `align-items:stretch`、`height:auto`；`textarea` 顶部对齐（`padding:13px 0`、`resize:none`），由组件控制高度而非用户拖拽。计数放 helper 右侧（`.count` 右浮，等宽数字）。

---

## 变体 Variants

| 变体 | 说明 |
|---|---|
| **fixed** | `rows` 固定（默认 3–4 行） |
| **auto-grow** | 随输入增高，封顶后内部滚动（JS 控高） |

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | `--border` + `--muted` 占位符 |
| **focus** | 边框 `--brand-strong` |
| **error** | 边框 + helper `--danger`（如超限） |
| **disabled** | 不透明度 45% + `--sunken` |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |
| `--muted` | `muted` | `0xFF6B6964` | `0xFF9A9893` |

---

## Flutter API

```dart
YhTextField(            // Textarea = TextField 的多行形态
  label: '意见反馈',
  hint: '说说你的想法…',
  maxLines: 4,
  maxLength: 200,       // 非空 = 显示计数
  helper: '请文明发言',
);
```

---

## Do & Don't

### ✅ Do
- 设上限时配实时计数（接近上限变色提醒）。
- 默认禁用用户拖拽手柄（`resize:none`），高度由组件管。

### ❌ Don't
- 让 textarea 文本竖向居中（多行应**顶部对齐**）。
- 不限长又不计数，导致超长文本破坏布局。

---

## 可交互样例

[`samples/textarea.html`](./samples/textarea.html) — 实时字数统计（输入即更新）。

## 无障碍 Accessibility

- 标签与 textarea 关联；计数用 `Semantics(liveRegion:true)` 在接近上限时播报。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 · 复用 .yh-field |
