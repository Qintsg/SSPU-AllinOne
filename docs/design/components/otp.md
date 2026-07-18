# OTP 验证码输入

> 分格输入的一次性验证码——每位一格，输入自动跳下格、退格回上格。登录 / 绑定 / 支付验证。

## 概述

- **用途**：短信 / 邮箱验证码、支付密码等定长数字串录入。
- **变体**：length 4 / 6（默认 6）；可分组（如 3+3）。
- **关键状态**：empty / focus（当前格）/ filled / error / complete。

---

## 解剖 Anatomy

```
┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐
│ 5│ │ 8│ │ 3│ │  │ │  │ │  │   ← 每格 48×56，等宽大号数字
└──┘ └──┘ └──┘ └▮─┘ └──┘ └──┘
 已填 border:--brand   当前格 focus border:--brand-strong
```

**必需元素**：N 个等宽单字符输入格（48×56，圆角 12，`--mono` 22px）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **empty** | `--border` 边框 |
| **focus** | 当前格边框 `--brand-strong` + 青雾光标 |
| **filled** | 已填格边框 `--brand`（亮支） |
| **error** | 全格边框 `--danger` + 抖动一次（可选） |
| **complete** | 填满自动提交 / 触发校验 |

> 交互：输入数字 → 自动聚焦下一格；退格在空格时回退上一格；支持整段粘贴自动分配。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | `brandStrong`（当前格 / 光标） | `0xFF478384` | `0xFF5C9A9B` |
| `--brand` | `brandPrimary`（已填格） | `0xFF6FA3A4` | `0xFF7FB0B1` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |
| `--danger` | `danger` | `0xFFC23B33` | `0xFFE5564B` |
| `--mono` | `fontFamilyMono` | 系统等宽字体栈 | 同 |

---

## Flutter API

```dart
class YhOtpField extends StatelessWidget {
  const YhOtpField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.error = false,
  });
  // N 个单字符 EditableText；自动跳格 / 退格回退 / 粘贴分配在 controller 层处理。
}
```

```dart
YhOtpField(length: 6, onCompleted: (code) => verify(code));
```

---

## Do & Don't

### ✅ Do
- 数字键盘（`keyboardType: number`）；自动跳格 + 退格回退 + 整段粘贴。
- 填满自动校验，减少一次"确认"点击。
- 错误时整组提示并清空，焦点回第一格。

### ❌ Don't
- 用单个长输入框冒充验证码（失去分格定位优势）。
- 格子过窄导致数字显示不全。
- 不支持粘贴（用户从短信复制时很痛）。

---

## 可交互样例

[`samples/otp.html`](./samples/otp.html) — 输入自动跳格、退格回退、错误态。

## 无障碍 Accessibility

- 整组 `Semantics(label:'6 位验证码')`；每格报"第 N 位"；完成时 `liveRegion` 播报"已填完"。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
