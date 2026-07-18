# Badge 徽标

> 挂在图标/头像右上角的未读提示——计数或红点。告知"这里有新内容"。

## 概述

- **用途**：未读计数、新内容红点（通知铃、底栏、头像）。
- **变体**：count（数字，超 99 显示 99+）/ dot（纯红点，无数字）。
- **关键状态**：有数 / 无数（隐藏）。

---

## 解剖 Anatomy

```
  ┌─┐③      ← 宿主图标右上角：计数胶囊或红点
  │🔔│        计数带 2px 描边（用宿主背景色，与图标分离）
  └─┘
```

**必需元素**：宿主（图标/头像）+ 角标（计数胶囊 18 高 / 红点 10）。计数描 2px `--surface` 边与底图分离。

---

## 变体 Variants

| 变体 | 视觉 | 用途 |
|---|---|---|
| **count** | 红底白字数字（99+ 封顶） | 可量化未读 |
| **dot** | 纯红点 | 仅表示"有新"，不计数 |

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **有数** | 显示角标 |
| **零** | 隐藏角标（不显示 0） |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--danger` | danger（角标底） | `#C23B33` | `#E5564B` |
| `--surface` | surface（描边） | `#FFFFFF` | `#1E2226` |

> 角标固定用 `--danger`（红），不随业务域色变化——红 = 通用"需注意"。

---

## Flutter API

```dart
class YhBadge extends StatelessWidget {
  const YhBadge({super.key, required this.child, this.count = 0, this.dot = false});
  // count>0 显示数字（>99 → '99+'）；dot=true 显示红点；count==0 && !dot 不显示。
}
```

```dart
YhBadge(count: 3, child: Icon(Icons.notifications));
YhBadge(dot: true, child: YhAvatar(text: '饶'));
```

---

## Do & Don't

### ✅ Do
- 计数 > 99 显示 `99+`；为 0 时隐藏。
- 角标描宿主背景色边，避免与深色图标糊在一起。

### ❌ Don't
- 显示"0"占位。
- 角标用业务域色（红色才是通用未读语义）。

---

## 可交互样例

[`samples/badge.html`](./samples/badge.html)

## 无障碍 Accessibility

- 宿主 `Semantics(label:'通知，3 条未读')`；纯装饰角标 `excludeSemantics`，语义并入宿主标签。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
