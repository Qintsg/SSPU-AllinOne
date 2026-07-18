# Switch 开关

> 即时生效的二元开关——用于设置项的 开/关，拨动立即应用，无需确认。

## 概述

- **用途**：即时生效的布尔设置（推送通知、深色模式、本地缓存）。
- **变体**：单一变体（含 disabled）。
- **关键状态**：off / on / disabled。

---

## 解剖 Anatomy

```
 off ╭───────╮      on ╭───────╮
     │○      │         │      ●│   ← 轨道 44×26 圆角 full；滑块 20 白圆
     ╰───────╯         ╰───────╯
   轨道 --border        轨道 --brand-strong
```

**必需元素**：轨道（44×26，圆角 full）、滑块（20 白圆 + `shadow-1`）。

---

## 状态 States

| 状态 | 轨道 | 滑块位置 |
|---|---|---|
| **off** | `--border` | 左（3px） |
| **on** | `--brand-strong` | 右（21px） |
| **切换** | 背景 + 滑块 200ms 缓动 | — |
| **disabled** | 不透明度 40% | — |

> 即时生效：拨动即调用 `onChanged`，**不要**配"保存"按钮。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |
| 滑块 | `#FFFFFF`（两主题一致） | — | — |

---

## Flutter API

```dart
class YhSwitch extends StatelessWidget {
  const YhSwitch({super.key, required this.value, required this.onChanged, this.disabled = false});
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;
}
```

```dart
YhSwitch(value: pushOn, onChanged: (v) => setState(() => pushOn = v));
```

---

## Do & Don't

### ✅ Do
- 仅用于**即时生效**的开关；配左侧文字标签说明含义。
- 滑块保持白色（两主题一致），靠轨道色表达状态。

### ❌ Don't
- 用 Switch 表达"需要提交后才生效"的选择（那是 Checkbox）。
- 开关旁再放"应用"按钮（违背即时生效语义）。

---

## 可交互样例

[`samples/switch.html`](./samples/switch.html)

## 无障碍 Accessibility

- `Semantics(toggled: value, label: ...)`；触控区域含轨道周边补足 ≥ 44dp。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
