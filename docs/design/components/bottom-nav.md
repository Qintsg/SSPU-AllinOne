# BottomNav 底部导航

> 移动端主导航——3–5 个顶级入口，图标 + 文字，常驻屏幕底部。当前项青雾高亮。

## 概述

- **用途**：App 顶级模块切换（首页/课表/资讯/我的）。
- **变体**：3 / 4 / 5 项；可含中央 FAB 凸起（扩展）。
- **关键状态**：每项 rest / active；可带未读红点（见 Badge）。

---

## 解剖 Anatomy

```
┌──────────────────────────────────────┐
│  ⌂      ▦      ◰      ☺               │  ← 等宽 item，图标在上、标签在下
│ 首页   课表   资讯   我的              │
└──────────────────────────────────────┘
   ↑ active：青雾 + 图标加粗
```

**必需元素**：3–5 个等宽 item（图标 22 + 标签 11px）。当前项 `--brand-strong`、图标描边加粗。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | `--muted` 图标 + 标签 |
| **active** | `--brand-strong` + 图标 stroke 加粗 |
| **badge** | 图标右上未读红点/计数 |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--surface` | surface | `#FFFFFF` | `#1E2226` |
| `--brand-strong` | brandStrong（active） | `#478384` | `#5C9A9B` |
| `--muted` | muted（rest） | `#6B6964` | `#9A9893` |

---

## Flutter API

```dart
class YhBottomNav extends StatelessWidget {
  const YhBottomNav({super.key, required this.items, required this.index, required this.onChanged});
  // items: List<({IconData icon, String label, int badge})>
}
```

```dart
YhBottomNav(index: tab, onChanged: (i) => setState(() => tab = i), items: const [
  (icon: Icons.home, label: '首页', badge: 0),
  (icon: Icons.calendar_today, label: '课表', badge: 0),
  (icon: Icons.article, label: '资讯', badge: 3),
  (icon: Icons.person, label: '我的', badge: 0),
]);
```

---

## Do & Don't

### ✅ Do
- 项数 3–5；标签 2–3 字；图标语义清晰。
- 仅放**顶级**入口，二级页面不再换底栏内容。

### ❌ Don't
- 项数 > 5（拥挤，改抽屉/更多）。
- 只用图标无文字（识别成本高）。

---

## 可交互样例

[`samples/bottom-nav.html`](./samples/bottom-nav.html) — 点击切换 active。

## 无障碍 Accessibility

- 每项 `Semantics(selected:..., label:'$label')`；触控区 ≥ 48dp；未读数读作"N 条未读"。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
