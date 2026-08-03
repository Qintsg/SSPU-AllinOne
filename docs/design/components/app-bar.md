# AppBar 顶栏

> 页面顶部的标题与全局动作栏——返回/标题/操作图标。每个页面的"门头"，确立位置与可用动作。

## 概述

- **用途**：页面标题 + 返回 + 1–2 个全局动作（搜索、更多）。
- **变体**：surface（浅底，默认）/ brand（青雾实心，强调页）。
- **关键状态**：static / scrolled（滚动后加底分隔或阴影）。

---

## 解剖 Anatomy

```
┌──────────────────────────────────────┐
│ ‹  法律                 ⋮              │  ← 可选眉题
│    随应用发布的文本                    │  ← 标题仍可省略号截断
└──────────────────────────────────────┘
```

**槽位**：leading（返回/菜单，可省）、eyebrow（可选上下文眉题）、title（可省略号截断）、actions（0–2 个图标，多则收进 ⋮）。不传 eyebrow 时保持单层标题。

---

## 变体 Variants

| 变体 | 视觉 | 用途 |
|---|---|---|
| **surface** | 浅底 + 底分隔线 | 内容页（默认） |
| **brand** | `--brand-strong` 实心 + 白字图标 | 首页/品牌强调页 |

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **static** | 顶栏与内容平齐 |
| **scrolled** | 内容滚动后底部出现分隔线/轻阴影，强化层级 |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--surface` | surface | `#FFFFFF` | `#1E2226` |
| `--brand-strong` | brandStrong（brand 变体） | `#478384` | `#5C9A9B` |
| `--on-brand` | onBrand | `#FFFFFF` | `#0A0D12` |
| `--border` | border | `#D1CEC9` | `#353A3F` |

---

## Flutter API

```dart
class YhAppBar extends StatelessWidget {
  const YhAppBar({super.key, required this.title, this.eyebrow, this.leading, this.actions = const [], this.brand = false, this.scrolled = false, this.horizontalPadding, this.actionSpacing});
}
```

`horizontalPadding` 与 `actionSpacing` 仅用于 PDF/WebView 等工具栏密集的已冻结次级阅读页；值必须来自 `YhTheme.spacing`，动作仍限制为 1–2 个且每项保持 48dp 目标。

```dart
YhAppBar(title: '课程表', leading: YhIconButton(icon: YhIcons.back, semanticLabel: '返回', onTap: pop), actions: [YhIconButton(icon: YhIcons.search, semanticLabel: '搜索')]);

YhAppBar(eyebrow: '法律', title: '随应用发布的文本', leading: backButton, actions: [moreButton]);
```

---

## Do & Don't

### ✅ Do
- 标题简短并截断；动作图标 ≤ 2，多则收 ⋮。
- brand 变体仅用于首页/重点页，避免每页都实心。

### ❌ Don't
- 顶栏塞 3+ 个动作图标。
- 标题过长不截断撑破布局。

---

## 可交互样例

[`samples/app-bar.html`](./samples/app-bar.html) — surface / brand 两态。

## 无障碍 Accessibility

- 返回/动作图标必有 `semanticLabel`；标题作为页面 `Semantics(header:true)`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.4.1 | 2026-08-03 | 补充次级阅读页的 token 化横向边距与动作间距契约 |
| 0.4.0 | 2026-07-26 | 新增可选 eyebrow 双层标题，用于法律与外部内容等次级阅读页 |
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
