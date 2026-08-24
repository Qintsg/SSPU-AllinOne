# QuickLink 快捷入口

> 跳转外部服务的入口行——图标徽 + 名称/说明 + 外链箭头。超星、OA、图书馆等第三方系统的聚合入口。

## 概述

- **用途**：聚合跳转外部/第三方服务（超星学习通、OA、图书馆、一网通办）。
- **变体**：tile（带说明与业务域图标徽，默认）/ compact（卡片内紧凑操作）。
- **关键状态**：rest / hover / pressed。

---

## 解剖 Anatomy

```
┌──────────────────────────────┐
│ ▣  超星学习通          ↗      │  ← 图标徽 + 名称/说明 + 外链角标
│    课程学习 · 在线考试         │
└──────────────────────────────┘
```

**必需元素**：名称、外链箭头（↗ 表示跳出 App）。tile 必须带按校园业务域色生成的图标徽；compact 用于已经由父卡片完成分组的操作区，保留线性图标但省略徽底。**可选**：副说明、独立收藏按钮（仅 tile）。

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
| `--opacity-domain-tint`（业务域图标浅底） | `0.14` | `0.14` |

---

## Flutter API

```dart
class YhQuickLink extends StatelessWidget {
  const YhQuickLink({super.key, required this.icon, required this.label, required this.color, required this.onTap, this.subtitle, this.favorite = false, this.onToggleFavorite, this.width, this.variant = YhQuickLinkVariant.tile});
}

enum YhQuickLinkVariant { tile, compact }
```

```dart
YhQuickLink(icon: YhIcons.academic, label: '超星学习通', color: theme.color.serviceAcademic, subtitle: '课程学习 · 在线考试', onTap: confirmAndOpenChaoxing);
YhQuickLink(icon: YhIcons.library, label: '图书馆', color: theme.color.serviceQuickLink, variant: YhQuickLinkVariant.compact, onTap: confirmAndOpenLibrary);
```

---

## Do & Don't

### ✅ Do
- 外链用 ↗ 角标提示"跳出 App"，减少误解。
- 图标统一线性风格；名称简短，说明点明用途。
- compact 只用于父卡片内的 1–3 个常用入口；它不显示副说明或收藏按钮，也不在页面中独立使用。
- 收藏是独立 48dp 操作，不能让收藏点击同时触发外部跳转。
- 打开前进入外部网页确认页；需要 OA 认证的入口先检查本机是否存在可复用登录会话，只有保存凭据不能视为已登录。

### ❌ Don't
- 外链与内部页用同样视觉（用户分不清是否离开 App）。
- 一屏堆十几个 QuickLink 不分组。

---

## 可交互样例

[`samples/quick-link.html`](./samples/quick-link.html)

## 无障碍 Accessibility

- 主入口使用 `Semantics(button:true, label:'超星学习通，外部链接，将打开外部应用')`。
- 收藏按钮独立使用“收藏/取消收藏 + 入口名称”语义，不与主入口合并。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
| 0.2.0 | 2026-07-19 | 补齐业务域浅底、独立收藏、外部确认与认证门禁契约 |
