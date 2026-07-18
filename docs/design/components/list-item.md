# ListItem 列表行

> 列表的标准行——前导（头像/图标）+ 主次两行文本 + 尾随（时间/箭头/标签）。通知、消息、设置项的骨架。

## 概述

- **用途**：可滚动列表的单行（通知、消息、设置、搜索结果）。
- **变体**：基础（前导 + 主次文 + 尾随）；可省任意槽位。
- **关键状态**：rest / hover / pressed / selected。

---

## 解剖 Anatomy

```
┌──────────────────────────────────────┐
│ [图] 图书馆开放公告        资讯  ›    │  ← 行 height ~52，flex 居中
│ 12  信息公开网 · 今天                  │
└──────────────────────────────────────┘
  ↑前导 38   ↑主文 b / 次文 span       ↑尾随
```

**槽位**：leading（头像/图标/缩略图，可省）、main（主文 b + 次文 span）、trailing（时间/标签/箭头，可省）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | surface |
| **hover** | `--sunken` 底 |
| **pressed** | 轻微加深 |
| **selected** | `--brand-tint` 底（多选/当前项） |

行间用 1px `--border` 分隔，末行无分隔。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--surface` | `surface` | `0xFFFFFFFF` | `0xFF1E2226` |
| `--sunken` | `sunken`（hover） | `0xFFFAFAFA` | `0xFF181B1E` |
| `--brand-tint` | `brandTint`（前导徽/选中） | `0xFFE9F0F0` | `0xFF1E3233` |
| `--border` | `border`（分隔线） | `0xFFD1CEC9` | `0xFF353A3F` |

---

## Flutter API

```dart
class YhListItem extends StatelessWidget {
  const YhListItem({super.key, this.leading, required this.title, this.subtitle, this.trailing, this.onTap, this.selected = false});
}
```

```dart
YhListItem(
  leading: YhAvatar(text: '图'),
  title: '图书馆开放公告',
  subtitle: '信息公开网 · 今天',
  trailing: const Icon(YhIcons.chevronRight),
  onTap: open,
);
```

---

## Do & Don't

### ✅ Do
- 主文一行截断（`ellipsis`），次文弱化。
- 整行可点，触控区 ≥ 48dp。
- 尾随箭头表示可进入下一级。

### ❌ Don't
- 主次文都用同样字重/字号（无层级）。
- 前导图标大小不一导致左缘不齐。

---

## 可交互样例

[`samples/list-item.html`](./samples/list-item.html)

## 无障碍 Accessibility

- 整行 `Semantics(button:true, label:'$title，$subtitle')`；选中态 `selected:true`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
