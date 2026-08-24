# SourceBadge 来源标

> AI 回答里的引用来源标——小图标 + 来源名，浅青雾底。让 AI 答案"有出处、可追溯"，是工大聚合可信度的关键。

## 概述

- **用途**：AI 助手回答下方标注依据来源（FAQ 条目、教务文件、公众号原文）。
- **变体**：single（单来源）/ multi（多来源横向排列）。
- **关键状态**：static / hover（可点跳原文时）。

---

## 解剖 Anatomy

```
╭─────────────────────────╮
│ 📄  FAQ：如何查询考试安排  │  ← 文档图标 + 来源标题，浅青雾底
╰─────────────────────────╯
```

**必需元素**：来源类型图标（文档/链接/知识库）、来源标题。底色 `--brand-tint`、文字 `--brand-ink`。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **static** | 浅青雾底只读标 |
| **hover**（可点） | 底色加深 / 下划线，提示可跳原文 |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-tint` | brandTint（底） | `#E9F0F0` | `#1E3233` |
| `--brand-ink` | brandInk（文字） | `#356263` | `#A8CFCF` |
| `--brand-strong` | brandStrong（图标） | `#478384` | `#5C9A9B` |

---

## Flutter API

```dart
class YhSourceBadge extends StatelessWidget {
  const YhSourceBadge({super.key, required this.title, this.kind = YhSourceKind.faq, this.onTap});
}
```

```dart
Wrap(spacing: 8, children: [
  YhSourceBadge(title: 'FAQ：如何查询考试安排', kind: YhSourceKind.faq),
  YhSourceBadge(title: '教务处文件 2026-014', kind: YhSourceKind.doc, onTap: openDoc),
]);
```

---

## Do & Don't

### ✅ Do
- AI 答案凡有依据必带来源标——这是工大聚合"可信"的体现。
- 多来源横向 wrap，超出换行不挤压。
- 可点来源跳转原文/FAQ 详情。

### ❌ Don't
- 给无依据的 AI 生成内容硬加来源标（误导可信度）。
- 来源标题过长不截断。

---

## 可交互样例

[`samples/source-badge.html`](./samples/source-badge.html) — 配 AIMessage 使用（见校园域 AIMessage）。

## 无障碍 Accessibility

- `Semantics(label:'来源：FAQ 如何查询考试安排')`；可点时 `button:true`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
