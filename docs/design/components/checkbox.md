# Checkbox 复选框

> 多选场景的勾选控件——一组里可选 0..N 项，选中填青雾实心 + 白勾。

## 概述

- **用途**：多选（协议勾选、批量选择、多条件过滤）。
- **变体**：单一变体（含 indeterminate 半选，可选）。
- **关键状态**：unchecked / checked / disabled。

---

## 解剖 Anatomy

```
 ☐  未选            ☑  选中
 22×22 圆角 6        青雾实心 + 白勾 ✓
 边框 --border
```

**必需元素**：方框（22×22，圆角 6）、勾号（选中态白色 ✓）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **unchecked** | `--surface` 底 + `--border` 边框 |
| **checked** | `--brand-strong` 底 + `--brand-strong` 边框 + 白勾 |
| **indeterminate** | 青雾底 + 白横杠（可选） |
| **disabled** | 不透明度 40% |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--on-brand` | `onBrand` | `0xFFFFFFFF` | `0xFF0A0D12` |
| `--surface` | `surface` | `0xFFFFFFFF` | `0xFF1E2226` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |

---

## Flutter API

```dart
class YhCheckbox extends StatelessWidget {
  const YhCheckbox({super.key, required this.value, required this.onChanged, this.tristate = false, this.disabled = false});
  final bool? value;            // tristate 时可为 null（半选）
  final ValueChanged<bool?>? onChanged;
}
```

```dart
YhCheckbox(value: agreed, onChanged: (v) => setState(() => agreed = v ?? false));
```

---

## Do & Don't

### ✅ Do
- 多选用 Checkbox，单选用 Radio，即时开关用 Switch——三者分工不混。
- 方框配可点的右侧文字（点文字也能切换）。

### ❌ Don't
- 用 Checkbox 做"即时生效的设置开关"（那是 Switch）。
- 选中态用浅底（勾不清晰）——必须青雾实心 + 白勾。

---

## 可交互样例

[`samples/checkbox.html`](./samples/checkbox.html)

## 无障碍 Accessibility

- `Semantics(checked: value, label: ...)`；含文字标签整体触控区 ≥ 44dp。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
