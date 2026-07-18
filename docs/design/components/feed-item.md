# FeedItem 资讯条目

> 资讯流的单条卡片——来源标 + 时间 + 标题 + 摘要。比 ListItem 更重内容，用于新闻/动态流。

## 概述

- **用途**：资讯聚合流、院系动态、公众号推送条目。
- **变体**：text（纯文字，默认）/ with-thumb（右侧缩略图）。
- **关键状态**：rest / hover / read（已读弱化）。

---

## 解剖 Anatomy

```
┌──────────────────────────────────────┐
│ ⬡ 信息公开网 · 2 小时前                │  ← 来源标（青雾胶囊）+ 时间
│ 图书馆开放时间调整公告                  │  ← 标题 h4
│ 自下周起，图书馆周末开放至 22:00，自习…  │  ← 摘要 p（2 行截断）
└──────────────────────────────────────┘
```

**必需元素**：来源标、时间、标题。**可选**：摘要（2 行截断）、右侧缩略图。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | 卡片描边 |
| **hover** | 边框转 `--brand` |
| **read** | 标题降为 `--muted`（已读弱化，可选） |

---

## Token 映射

| 设计 token | 亮色 | 暗色 |
|---|---|---|
| `--surface` / `--border` | `#FFFFFF` / `#D1CEC9` | `#1E2226` / `#353A3F` |
| `--brand-tint` / `--brand-ink`（来源标） | `#E9F0F0` / `#356263` | `#1E3233` / `#A8CFCF` |
| `--muted`（时间/摘要） | `#6B6964` | `#9A9893` |

---

## Flutter API

```dart
class YhFeedItem extends StatelessWidget {
  const YhFeedItem({super.key, required this.source, required this.time, required this.title, this.excerpt, this.thumbUrl, this.onTap});
}
```

```dart
YhFeedItem(source: '信息公开网', time: '2 小时前', title: '图书馆开放时间调整公告', excerpt: '自下周起，图书馆周末开放至 22:00…', onTap: open);
```

---

## Do & Don't

### ✅ Do
- 来源 + 时间始终可见（资讯可信度）。
- 摘要 2 行截断，标题最多 2 行。
- 域来源可用对应业务域色做来源标（见 foundations/color.md）。

### ❌ Don't
- 摘要不截断导致条目高度失控。
- 无来源/时间的"裸标题"（降低可信度）。

---

## 可交互样例

[`samples/feed-item.html`](./samples/feed-item.html)

## 无障碍 Accessibility

- 整条 `Semantics(button:true, label:'$source，$time，$title')`；已读态用 `label` 注明"已读"。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
