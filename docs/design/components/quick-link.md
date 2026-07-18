# QuickLink 快捷入口

> 跳转外部服务的入口行——图标徽 + 名称/说明 + 外链箭头。超星、OA、图书馆等第三方系统的聚合入口。

## 概述

- **用途**：聚合跳转外部/第三方服务（超星学习通、OA、图书馆、一网通办）。
- **变体**：row（横向行，默认）/ tile（宫格，见 Tile）。
- **关键状态**：rest / hover / pressed。

---

## 解剖 Anatomy

```
┌──────────────────────────────┐
│ ▣  超星学习通          ↗      │  ← 图标徽 + 名称/说明 + 外链角标
│    课程学习 · 在线考试         │
└──────────────────────────────┘
```

**必需元素**：图标徽（青雾）、名称。**可选**：副说明、外链箭头（↗ 表示跳出 App）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | 卡片描边 |
| **hover** | 边框转 `--brand` |
| **pressed** | 轻微缩放（可选） |

外链用 ↗（右上箭头）明确"将跳转到外部"。

---

## Token 映射

| 设计 token | 亮色 | 暗色 |
|---|---|---|
| `--surface` / `--border` | `#FFFFFF` / `#D1CEC9` | `#1E2226` / `#353A3F` |
| `--brand-tint` / `--brand-strong`（图标徽） | `#E9F0F0` / `#478384` | `#1E3233` / `#5C9A9B` |
| `--muted`（说明/箭头） | `#6B6964` | `#9A9893` |

---

## Flutter API

```dart
class YhQuickLink extends StatelessWidget {
  const YhQuickLink({super.key, required this.icon, required this.title, this.subtitle, this.external = true, this.onTap});
}
```

```dart
YhQuickLink(icon: YhIcons.academic, title: '超星学习通', subtitle: '课程学习 · 在线考试', onTap: openChaoxing);
```

---

## Do & Don't

### ✅ Do
- 外链用 ↗ 角标提示"跳出 App"，减少误解。
- 图标统一线性风格；名称简短，说明点明用途。

### ❌ Don't
- 外链与内部页用同样视觉（用户分不清是否离开 App）。
- 一屏堆十几个 QuickLink 不分组。

---

## 可交互样例

[`samples/quick-link.html`](./samples/quick-link.html)

## 无障碍 Accessibility

- `Semantics(button:true, label:'超星学习通，外部链接')`；外链提示"将打开外部应用"。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
