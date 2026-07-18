# TextField 文本输入框

> 单行文本录入的基础控件——标签在上、控件行内文本与前/后置图标统一竖向居中。响应色 `#478384`。

## 概述

- **用途**：单行文本 / 邮箱 / 密码等录入。
- **变体**：default / with-icon（前置或后置图标）/ textarea（多行）。
- **关键状态**：rest / focus / filled / error / disabled。

---

## 解剖 Anatomy

```
学号                         ← 标签 flabel（在控件上方，--muted）
┌─────────────────────────────┐
│ [ic] 10  请输入 10 位学号     │  ← 控件行 height 48，flex align-items:center
└─────────────────────────────┘
10 位数字                      ← helper 辅助/错误文字
```

**布局契约**：控件行用 `display:flex; align-items:center`，输入文本与前/后置图标都是 flex 同级，**天然竖向居中、互不重合**。输入框**不得**用 `padding-top` 给浮动标签让位——标签独立放在控件上方。

**必需元素**：标签（上方）、控件行（容器 + input）。
**可选元素**：前置图标（prefix）、后置图标（suffix，如密码眼睛 / 清除）、helper。

---

## 变体 Variants

| 变体 | 视觉 | 说明 |
|---|---|---|
| **default** | 1.5px 边框 + 圆角 12 | 标准录入 |
| **with-icon** | 前置 / 后置 20×20 线性图标 | 图标 `--muted`，聚焦时前置转 `--brand-strong` |
| **textarea** | 控件行 `align-items:stretch` + 多行 | 顶部对齐，可配字数计数 |

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | `--border` 边框 + `--muted` 占位符 |
| **focus** | 边框 `--brand-strong`（`:focus-within`） |
| **filled** | 正文 `--fg` |
| **error** | 边框 + helper `--danger` |
| **disabled** | 不透明度 45% + `--sunken` 底 + `not-allowed` |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--surface` | `surface` | `0xFFFFFFFF` | `0xFF1E2226` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |
| `--muted` | `muted` | `0xFF6B6964` | `0xFF9A9893` |
| `--danger` | `danger` | `0xFFC23B33` | `0xFFE5564B` |
| 输入圆角 12 | `radiusInput` | `12.0` | `12.0` |

---

## Flutter API

```dart
class YhTextField extends StatelessWidget {
  const YhTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,            // 非空 = error 态
    this.prefixIcon,
    this.suffixIcon,
    this.obscure = false,      // 密码
    this.maxLines = 1,         // >1 = textarea
    this.enabled = true,
  });
  // 自建外壳：Column(label, Container(border)->Row(prefix, EditableText, suffix), helper)
  // EditableText 垂直居中由 Row crossAxisAlignment.center 保证；禁止 padding-top hack。
}
```

```dart
YhTextField(label: '学号', hint: '请输入 10 位学号', helper: '10 位数字');
YhTextField(label: '用户名', prefixIcon: YhIcons.profile);
YhTextField(label: '密码', obscure: true, suffixIcon: YhIcons.visibility);
YhTextField(label: '意见反馈', maxLines: 3, helper: '请文明发言');
```

---

## Do & Don't

### ✅ Do
- 标签放控件上方，正文与图标用 flex `align-items:center` 居中。
- 占位符用 `--muted`（可见），不要设为透明。
- 前/后置图标固定 20×20、`flex-shrink:0`，与文本留 10px 间距。

### ❌ Don't
- 给 input 加 `padding-top` 让文本偏离竖向中线。
- 用绝对定位的浮动标签压在前置图标上（会重合）。
- 把占位符设成 `transparent`（搜索框文字会消失）。

---

## 可交互样例

[`samples/text-field.html`](./samples/text-field.html) — default / 图标 / textarea / error / disabled，亮暗双主题。

## 无障碍 Accessibility

- 控件行高 48dp（触控达标）；`label` 与 input 关联；error 用 `Semantics(liveRegion:true)` 播报。
- 占位符不替代标签——标签始终可见。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.2.0 | 2026-06-16 | 响应色 #478384 · 浮动标签改为标签在上 · 修正文本/图标竖向居中与重合 · 接入共享样例 |
| 0.1.0 | 2026-06-16 | 初始规格 |
