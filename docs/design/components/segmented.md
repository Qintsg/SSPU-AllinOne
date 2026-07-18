# SegmentedControl 分段控制器

> 2–4 个互斥选项的就地切换——比 Tabs 轻、比 Radio 紧凑，常用于"全部 / 未读 / 已读"这类视图过滤。

## 概述

- **用途**：少量（2–4）互斥选项的即时切换，结果就地生效。
- **变体**：单一变体；段数 2–4。
- **关键状态**：每段 rest / selected；整体 disabled。

---

## 解剖 Anatomy

```
╭───────────────────────────╮
│ ▣ 全部 │  未读  │  已读     │  ← 轨道 --brand-tint，圆角 10，内边距 3
╰───────────────────────────╯
   ↑ 选中段：白面 + 青雾字 + shadow-1
```

**必需元素**：轨道容器（`bg: --brand-tint`，圆角 10，padding 3）、2–4 个段按钮。
选中段：`bg: --surface` + `fg: --brand-strong` + `shadow-1`；未选段：`fg: --muted` 透明底。

---

## 变体 Variants

仅段数差异（2 / 3 / 4）。**超过 4 段改用 Tabs**——分段控制器靠等宽并排，段多会过窄。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **段 rest** | 弱化色字 + 透明底 |
| **段 selected** | 白面滑块 + 青雾字 + `shadow-1` |
| **切换** | 滑块 200ms 缓动平移（可选） |
| **disabled** | 整体不透明度 40% |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-tint` | `brandTint` | `0xFFE9F0F0` | `0xFF1E3233` |
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--surface` | `surface` | `0xFFFFFFFF` | `0xFF1E2226` |
| `--muted` | `muted` | `0xFF6B6964` | `0xFF9A9893` |
| `--radius-s` | `radiusSmall` | `10.0` | `10.0` |

---

## Flutter API

```dart
class YhSegmented<T> extends StatelessWidget {
  const YhSegmented({
    super.key,
    required this.segments,    // List<({T value, String label})>
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });
}
```

```dart
YhSegmented<String>(
  segments: const [(value: 'all', label: '全部'), (value: 'unread', label: '未读'), (value: 'read', label: '已读')],
  value: filter,
  onChanged: (v) => setState(() => filter = v),
);
```

---

## Do & Don't

### ✅ Do
- 段数 2–4；标签短（2–4 字）等长更佳。
- 结果就地即时生效，不需"应用"按钮。
- 始终有一个选中段（不可全空）。

### ❌ Don't
- 段数 > 4（改 Tabs）。
- 段标签长短悬殊导致宽度跳动。
- 用它做"页面跳转"——那是 Tabs / 导航的职责。

---

## 可交互样例

[`samples/segmented.html`](./samples/segmented.html)

## 无障碍 Accessibility

- `Semantics`：每段 `inMutuallyExclusiveGroup: true, selected: ...`；键盘左右方向键切换。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
