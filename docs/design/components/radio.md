# Radio 单选

> 一组里只能选一项的互斥控件——选中显示青雾环 + 青雾实心点。

## 概述

- **用途**：少量（2–5）互斥选项的单选（性别、主题、排序方式）。
- **变体**：单一变体。
- **关键状态**：unselected / selected / disabled。

---

## 解剖 Anatomy

```
 ○  未选            ◉  选中
 22×22 圆          青雾环 + 青雾实心点（10）
 边框 --border
```

**必需元素**：圆框（22×22）、内点（选中态 `--brand-strong` 实心，10×10）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **unselected** | `--surface` 底 + `--border` 边框 |
| **selected** | `--brand-strong` 边框 + `--brand-strong` 内点 |
| **disabled** | 不透明度 40% |

> 组内互斥：选中一项自动取消其余；**组内必须始终有一项选中**（或提供"不选"显式项）。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--surface` | `surface` | `0xFFFFFFFF` | `0xFF1E2226` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |

---

## Flutter API

```dart
class YhRadio<T> extends StatelessWidget {
  const YhRadio({super.key, required this.value, required this.groupValue, required this.onChanged, this.disabled = false});
  final T value;
  final T? groupValue;          // == value 即选中
  final ValueChanged<T?>? onChanged;
}
```

```dart
YhRadio<String>(value: 'time', groupValue: sortBy, onChanged: (v) => setState(() => sortBy = v));
```

---

## Do & Don't

### ✅ Do
- 选项 2–5 个用 Radio；更多改 Select/Dropdown。
- 选项互斥且需"提交后生效"时用 Radio；即时切换视图用 Segmented。

### ❌ Don't
- 用 Radio 做多选（那是 Checkbox）。
- 组内默认全空又不提供"不选"项。

---

## 可交互样例

[`samples/radio.html`](./samples/radio.html)

## 无障碍 Accessibility

- `Semantics(inMutuallyExclusiveGroup: true, checked: selected, label: ...)`；方向键在组内移动。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
