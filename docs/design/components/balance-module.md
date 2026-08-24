# BalanceModule 校园卡余额

> 校园卡的余额面板——青雾色面 + 大号余额 + 快捷动作（充值/明细）。首页"钱"模块的门面。

## 概述

- **用途**：校园卡/账户余额展示 + 充值/明细入口。
- **变体**：full（余额 + 双动作，默认）/ compact（仅余额，嵌入更大卡）。
- **关键状态**：正常 / 余额不足（转警示色提示）。

---

## 解剖 Anatomy

```
┌──────────────────────────────┐
│ 校园卡余额                     │  ← 标签（白字 82% 透明）
│ ¥128.50                       │  ← 余额 v（等宽 30px 白字）
│ [ 充值 ]  [ 明细 ]             │  ← 快捷动作（半透明白底按钮）
└──────────────────────────────┘
 青雾色面 --brand-strong + 白字常驻
```

**必需元素**：标签、余额（等宽）。**可选**：快捷动作按钮、今日消费小字。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **正常** | 青雾色面 + 白字 |
| **余额不足** | 余额下方加警示小字（"余额不足，请充值"） |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | brandStrong（色面） | `#478384` | `#5C9A9B` |
| 白字 | 固定 `#FFFFFF`（色面上常驻白字） | — | — |
| `--mono` | fontFamilyMono（余额） | 系统等宽字体栈 | 同 |

> 余额面用青雾实心 + 白字（两主题一致），靠色面与页面区分；不随主题翻成浅底。

---

## Flutter API

```dart
class YhBalanceModule extends StatelessWidget {
  const YhBalanceModule({super.key, required this.balance, this.onRecharge, this.onDetail, this.lowBalance = false});
}
```

```dart
YhBalanceModule(balance: '¥128.50', onRecharge: recharge, onDetail: openBills);
```

---

## Do & Don't

### ✅ Do
- 余额等宽大号，第一眼可读。
- 充值/明细就近放，减少跳转层级。
- 金额用真实数据或明确占位，不编造。

### ❌ Don't
- 色面用花哨渐变（保持单一青雾实色）。
- 把无关信息塞进余额面（聚焦"钱"）。

---

## 可交互样例

[`samples/balance-module.html`](./samples/balance-module.html)

## 无障碍 Accessibility

- `Semantics(label:'校园卡余额 128.50 元')`；充值/明细按钮各自可达、有标签。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
