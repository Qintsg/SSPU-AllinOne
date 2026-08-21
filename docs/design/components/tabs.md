# Tabs 标签页

> 同层内容的分组切换——下划线指示当前页。比 Segmented 容纳更多项，常用于详情页内分区。

## 概述

- **用途**：同一页面内的内容分区切换（全部/通知/动态/学院）。
- **变体**：underline（下划线，默认）/ scrollable（项多时横向滚动）。
- **关键状态**：每项 rest / hover / active。

---

## 解剖 Anatomy

```
全部   通知   动态   学院
━━━━                          ← active 下划线 2px 青雾
└ 底部 1.5px 分隔贯穿
```

**必需元素**：标签项行 + 底分隔线；active 项底部 2px `--brand-strong` 下划线 + 青雾字。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | `--muted` 字、无下划线 |
| **hover** | 字转 `--fg` |
| **active** | `--brand-strong` 字 + 2px 青雾下划线 |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | brandStrong（active） | `#478384` | `#5C9A9B` |
| `--muted` | muted（rest） | `#6B6964` | `#9A9893` |
| `--border` | border（底线） | `#D1CEC9` | `#353A3F` |

---

## Flutter API

```dart
class YhTabs extends StatelessWidget {
  const YhTabs({super.key, required this.tabs, required this.index, required this.onChanged, this.scrollable = false});
}
```

```dart
YhTabs(tabs: const ['全部','通知','动态','学院'], index: i, onChanged: (v)=>setState(()=>i=v));
```

---

## Do & Don't

### ✅ Do
- 与 Segmented 区分：Tabs 切换**页面内容区**，Segmented 多用于就地过滤。
- 项多时横向可滚动，不要挤压换行。

### ❌ Don't
- 2–3 个短互斥项还用 Tabs（Segmented 更紧凑）。
- 下划线用多色（保持单一青雾）。

---

## 可交互样例

[`samples/tabs.html`](./samples/tabs.html) — 点击切换 active。

## 无障碍 Accessibility

- `role=tablist` / `tab` / `tabpanel`；方向键切换，`aria-selected` 标注当前。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
