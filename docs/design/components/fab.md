# FAB 悬浮行动按钮

> 页面级唯一主行动的承载者——浮于内容之上，青雾实心 + 阴影，永远指向"此页最该做的那件事"。

## 概述

- **用途**：页面最高优先级的单一行动（新建课程、写反馈、发消息）。
- **变体**：regular（56×56 圆角方）/ extended（图标 + 文字胶囊）。
- **关键状态**：rest / hover / pressed / focus。

---

## 解剖 Anatomy

```
        ╭────╮            ╭───────────────╮
        │ +  │            │  +  新建课程   │
        ╰────╯            ╰───────────────╯
      regular 56×56        extended 自适应宽
   radius=16 · shadow-2      高 56 · 左右 20
```

**必需元素**：实心容器（56×56dp，圆角 16，`shadow-2`）、图标（26×26，2px 描边）。
**extended 追加**：文本标签（w600 15px）。

---

## 变体 Variants

| 变体 | 视觉 | token | 用途 |
|---|---|---|---|
| **regular** | 56×56 圆角方 + 图标 | `bg: --brand-strong` · `fg: --on-brand` | 图标含义明确时 |
| **extended** | 图标 + 文字胶囊 | 同上 + `padding: 0 20px` | 首次引导 / 含义需文字补充 |

定位惯例：右下角，距屏幕边 16dp，避开底栏（底栏存在时上移到底栏之上 16dp）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | 青雾实心 + `shadow-2` |
| **hover** | `brightness(0.95)` + `shadow-3`（抬升） |
| **pressed** | `scale(0.96)` |
| **focus** | 外轮廓 2px `--brand` |
| **scroll** | 列表下滑时可收为 regular，上滑恢复 extended（可选动效） |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--on-brand` | `onBrand` | `0xFFFFFFFF` | `0xFF0A0D12` |
| `--radius-m` | `radiusMedium` | `16.0` | `16.0` |
| `--shadow-2` | `elevation2` | `0 4 12 / 12%` | `0 4 12 / 50%` |

---

## Flutter API

```dart
class YhFab extends StatelessWidget {
  const YhFab({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.label,                 // 非空 = extended
    this.onTap,
  });
  bool get extended => label != null;
}
```

```dart
YhFab(icon: YhIcons.add, semanticLabel: '新建', onTap: create);
YhFab(icon: YhIcons.edit, semanticLabel: '写反馈', label: '写反馈', onTap: openForm);
```

---

## Do & Don't

### ✅ Do
- **一页一个 FAB**——它代表本页唯一主行动。
- 图标含义不明时用 extended 加文字。
- 与底栏共存时上移，避免遮挡导航。

### ❌ Don't
- 一页多个 FAB（行动优先级冲突）。
- 用 FAB 承载"返回""取消"这类非主行动。
- 滚动时遮挡关键内容却不让位。

---

## 可交互样例

[`samples/fab.html`](./samples/fab.html)

## 无障碍 Accessibility

- 触控区域 56×56dp；`Semantics(button: true, label: semanticLabel)`。
- 与底栏共存时确保不遮挡可点元素。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
