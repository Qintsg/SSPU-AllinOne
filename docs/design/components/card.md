# Card 卡片

> 内容分组的基础容器——把相关信息聚成一块。清源卡片用柔边框 / 浅阴影 + 16px 圆角，承载标题、正文与操作。

## 概述

- **用途**：聚合一组相关内容（通知、课程、设置项）。
- **变体**：outlined（描边，默认）/ elevated（阴影浮起）。
- **关键状态**：static / hover（可点卡片）。

---

## 解剖 Anatomy

```
┌─────────────────────────────┐
│ 标题                          │  ← ttl
│ 正文说明…                     │  ← desc（--muted）
│ [主操作] [次操作]             │  ← foot（可选）
└─────────────────────────────┘
 surface + 1.5px border + radius 16 + padding 20
```

**必需元素**：容器（surface + border/shadow + 圆角 16）。**可选**：标题、正文、底部操作区。

---

## 变体 Variants

| 变体 | 视觉 | 用途 |
|---|---|---|
| **outlined** | 1.5px `--border` 描边、无阴影 | 列表内密集卡片（默认） |
| **elevated** | 无边框 + `--shadow-2` | 需从背景中浮起强调 |

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **static** | 默认 |
| **hover**（可点） | 边框转 `--brand` 或轻微抬升 `--shadow-2` |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--surface` | `surface` | `0xFFFFFFFF` | `0xFF1E2226` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |
| `--radius-m` | `radiusMedium` | `16.0` | `16.0` |
| `--shadow-2` | `elevation2` | `0 4 12 / 12%` | `0 4 12 / 50%` |

---

## Flutter API

```dart
class YhCard extends StatelessWidget {
  const YhCard({super.key, required this.child, this.elevated = false, this.onTap, this.padding = const EdgeInsets.all(20)});
}
```

```dart
YhCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('缴费通知'), ...]));
YhCard(elevated: true, onTap: open, child: ...);
```

---

## Do & Don't

### ✅ Do
- 一张卡一个主题；卡内层级清晰（标题 > 正文 > 操作）。
- 密集列表用 outlined，单张强调用 elevated。

### ❌ Don't
- 卡里再套卡套卡（层级混乱）。
- outlined + elevated 叠用（边框 + 阴影双重描边显脏）。
- 卡片左侧加彩色竖条做强调（AI slop）。

---

## 可交互样例

[`samples/card.html`](./samples/card.html)

## 无障碍 Accessibility

- 可点卡片整体 `Semantics(button:true)`；卡内交互元素单独可达。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
