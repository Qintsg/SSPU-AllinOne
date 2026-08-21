# Chip 筹码

> 可点选的小标签——用于多选筛选、标签输入、快捷过滤。选中即填青雾浅底。

## 概述

- **用途**：筛选标签（可多选）、属性标记、快捷入口。
- **变体**：filter（可选中，默认）/ input（带删除 ×）/ static（只读标记，见 Tag/StatusPill）。
- **关键状态**：rest / hover / selected / disabled。

---

## 解剖 Anatomy

```
╭───────────────╮      ╭───────────────╮
│ ✓  已选        │      │  教务      ×   │
╰───────────────╯      ╰───────────────╯
 filter 选中态           input 带删除
 圆角 full · 高 ~30
```

**必需元素**：胶囊容器（圆角 full，padding 7×14）、文本。
**可选**：前置勾选图标（选中态）、尾随删除 ×（input 型）。

---

## 变体 Variants

| 变体 | rest | selected | token |
|---|---|---|---|
| **filter** | 透明底 + 边框 + 弱化字 | `--brand-tint` 底 + `--brand-ink` 字 + 青雾边框 | 可多选 |
| **input** | 同 filter + 尾随 × | — | 已输入标签，× 可删 |

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | 透明底 + `--border` 边框 + `--muted` 字 |
| **hover** | 边框转 `--brand` |
| **selected** | `--brand-tint` 底 + `--brand-ink` 字 + 青雾边框 + 前置 ✓ |
| **disabled** | 不透明度 40% |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-tint` | `brandTint` | `0xFFE9F0F0` | `0xFF1E3233` |
| `--brand-ink` | `brandInk` | `0xFF356263` | `0xFFA8CFCF` |
| `--brand` | `brandPrimary` | `0xFF6FA3A4` | `0xFF7FB0B1` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |
| `--muted` | `muted` | `0xFF6B6964` | `0xFF9A9893` |
| `--radius-full` | `radiusFull` | `999` | `999` |

---

## Flutter API

```dart
class YhChip extends StatelessWidget {
  const YhChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDeleted,            // 非空 = input 型，显示尾随 ×
    this.disabled = false,
  });
}
```

```dart
YhChip(label: '教务', selected: f.contains('教务'), onTap: () => toggle('教务'));
YhChip(label: '高数', onDeleted: () => removeTag('高数')); // input 型
```

---

## Do & Don't

### ✅ Do
- filter 组允许多选，与 Segmented（互斥）区分清楚。
- 选中态用青雾浅底而非实心——保持轻量。
- 标签短（≤ 5 字）。

### ❌ Don't
- 用 Chip 做主行动（那是 Button）。
- 选中态用 `--brand-strong` 实心填充（太重，像按钮）。
- 一行塞十几个 chip 不换行/不滚动。

---

## 可交互样例

[`samples/chip.html`](./samples/chip.html)

## 无障碍 Accessibility

- `Semantics(button: true, selected: selected, label: label)`；input 型的 × 单独可聚焦并带 `label: '删除 $label'`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
