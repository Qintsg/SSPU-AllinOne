# NavRail 侧边导航轨

> 平板/桌面的纵向主导航——窄轨贴左，图标 + 短标签，当前项青雾胶囊。BottomNav 的大屏对应物。

## 概述

- **用途**：平板横屏 / 桌面的顶级模块导航（替代底栏）。
- **变体**：compact（仅图标 + 短标签，默认 80px 宽）/ extended（展开为图标 + 完整文字行）。
- **关键状态**：每项 rest / hover / active。

---

## 解剖 Anatomy

```
┌────┐
│ ⌂  │  首页   ← active：青雾胶囊底
│ 首页│
├────┤
│ ▦  │  课表
│ 课表│
└────┘
 宽 80（compact）
```

**必需元素**：纵向 item 列（图标 22 + 标签 11）。当前项 `--brand-tint` 胶囊底 + `--brand-strong` 字。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | `--muted` |
| **hover** | `--sunken` 底 |
| **active** | `--brand-tint` 底 + `--brand-strong` 图标文字 |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--surface` | surface | `#FFFFFF` | `#1E2226` |
| `--brand-tint` | brandTint（active 底） | `#E9F0F0` | `#1E3233` |
| `--brand-strong` | brandStrong（active 字） | `#478384` | `#5C9A9B` |
| `--sunken` | sunken（hover） | `#FAFAFA` | `#181B1E` |

---

## Flutter API

```dart
class YhNavRail extends StatelessWidget {
  const YhNavRail({super.key, required this.items, required this.index, required this.onChanged, this.extended = false});
}
```

```dart
Row(children: [
  YhNavRail(index: tab, onChanged: (i)=>setState(()=>tab=i), items: navItems),
  const VerticalDivider(width: 1),
  Expanded(child: page),
]);
```

---

## Do & Don't

### ✅ Do
- 大屏（≥ 768px）用 NavRail，小屏用 BottomNav，共享同一套 items 数据。
- active 用胶囊底而非整列高亮。

### ❌ Don't
- 小屏强塞 NavRail（挤占横向空间）。
- 同屏既有 NavRail 又有 BottomNav（导航重复）。

---

## 可交互样例

[`samples/nav-rail.html`](./samples/nav-rail.html)

## 无障碍 Accessibility

- `Semantics(selected:..., label:'$label')`；键盘上下方向键在轨内移动。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
