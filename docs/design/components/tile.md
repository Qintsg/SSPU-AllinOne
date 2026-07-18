# Tile 磁贴

> 首页 / 快捷区的可点入口块——图标在上、标题副标在下，纵向紧凑，成网格排列。

## 概述

- **用途**：功能入口宫格（教务、课表、缴费、图书馆）。
- **变体**：icon-tile（图标 + 文字，默认）/ stat-tile（数字 + 标签，见 MetricCard）。
- **关键状态**：rest / hover / pressed。

---

## 解剖 Anatomy

```
┌───────────┐
│  ▣        │  ← 图标徽 40×40（brand-tint 底 + 青雾图标）
│  教务      │  ← 标题 b
│  成绩查询  │  ← 副标 span（--muted）
└───────────┘
 150 宽 · radius 24 · padding 16
```

**必需元素**：图标徽、标题。**可选**：副标。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | surface + border |
| **hover** | 边框转 `--brand` + 上移 2px + `--shadow-2` |
| **pressed** | 回落（可选 `scale`） |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-tint` | `brandTint`（图标底） | `0xFFE9F0F0` | `0xFF1E3233` |
| `--brand-strong` | `brandStrong`（图标） | `0xFF478384` | `0xFF5C9A9B` |
| `--brand` | `brandPrimary`（hover 边框） | `0xFF6FA3A4` | `0xFF7FB0B1` |
| `--radius-l` | `radiusLarge` | `24.0` | `24.0` |

---

## Flutter API

```dart
class YhTile extends StatelessWidget {
  const YhTile({super.key, required this.icon, required this.title, this.subtitle, this.onTap});
}
```

```dart
GridView.count(crossAxisCount: 4, children: [
  YhTile(icon: Icons.school, title: '教务', subtitle: '成绩查询', onTap: openEams),
  YhTile(icon: Icons.calendar_today, title: '课表', onTap: openSchedule),
]);
```

---

## Do & Don't

### ✅ Do
- 图标用统一线性风格（1.8px 描边）。
- 标题 ≤ 4 字，副标可省。
- 业务域 Tile 可用对应域色做图标底（见 foundations/color.md 八业务域）。

### ❌ Don't
- 图标用 emoji 充数（🎯🚀）。
- 一屏宫格 > 8 个还不分组。

---

## 可交互样例

[`samples/tile.html`](./samples/tile.html)

## 无障碍 Accessibility

- 整块 `Semantics(button:true, label:'$title $subtitle')`；触控区 ≥ 64×64dp。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
