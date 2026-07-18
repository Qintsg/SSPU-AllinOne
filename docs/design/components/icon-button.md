# IconButton 图标按钮

> 仅用图标表达的紧凑行动——顶栏 / 工具栏 / 列表尾随处的次要操作。

## 概述

- **用途**：空间紧张处的次要行动（搜索、通知、更多、关闭）。
- **变体**：outline（描边）/ ghost（无边框）。
- **关键状态**：rest / hover / pressed / focus / disabled。

---

## 解剖 Anatomy

```
┌──────┐
│  ⌕   │  ← 容器 48×48dp, radius=10；图标 20×20 居中
└──────┘
```

**必需元素**：方形容器（48×48dp，满足最小触控区）、单个线性图标（20×20，1.8px 描边，`currentColor`）。
**禁止**：图标 + 文字混排（那是 Button 的职责）。

---

## 变体 Variants

| 变体 | 视觉 | token |
|---|---|---|
| **outline** | 1.5px 边框 + 弱化色图标 | `border: --border` · `fg: --muted` |
| **ghost** | 无边框透明底 | `fg: --muted` |

hover 时两者都转为青雾：`fg: --brand-strong`（outline 边框同步变 `--brand-strong`，ghost 加 `--brand-tint` 底）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | 弱化色图标 |
| **hover** | 图标 → 青雾；outline 边框变青雾，ghost 加青雾浅底 |
| **pressed** | `scale(0.96)` |
| **focus** | 外轮廓 2px `--brand` |
| **disabled** | 不透明度 40% + `not-allowed` |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--muted` | `muted` | `0xFF6B6964` | `0xFF9A9893` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--brand-tint` | `brandTint` | `0xFFE9F0F0` | `0xFF1E3233` |
| `--radius-s` | `radiusSmall` | `10.0` | `10.0` |

---

## Flutter API

```dart
enum YhIconButtonVariant { outline, ghost }

class YhIconButton extends StatelessWidget {
  const YhIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,   // 必填：无障碍标签
    this.onTap,
    this.variant = YhIconButtonVariant.outline,
    this.disabled = false,
    this.size = 44.0,
  });
  // icon: IconData / 自绘 SVG path；semanticLabel 喂给 Semantics(button:true,label:)
}
```

```dart
YhIconButton(icon: YhIcons.search, semanticLabel: '搜索', onTap: openSearch);
YhIconButton(icon: YhIcons.more, semanticLabel: '更多', variant: YhIconButtonVariant.ghost);
```

---

## Do & Don't

### ✅ Do
- **必给 `semanticLabel`**——图标按钮无文字，无障碍只能靠它。
- 容器 ≥ 48×48dp，即使图标只有 20px。
- 同一工具栏图标风格一致（同为 1.8px 线性）。

### ❌ Don't
- 用 IconButton 承载主要行动（那是 Button）。
- 图标语义不清（如用 ⚙ 表达"保存"）。
- 一排塞 5+ 个图标按钮——超过 3 个考虑收进"更多"菜单。

---

## 可交互样例

[`samples/icon-button.html`](./samples/icon-button.html)

## 无障碍 Accessibility

- 触控区域 48×48dp；`Semantics(button: true, label: semanticLabel)` 必填。
- hover/focus 反馈明确，键盘 Tab 可达。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
