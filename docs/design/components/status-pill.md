# StatusPill 状态药丸

> 表达对象状态的小标签——前导圆点 + 文字，四语义：成功 / 警告 / 错误 / 信息。只读，不可点。

## 概述

- **用途**：标注条目状态（已签到 / 待提交 / 异常 / 进行中）。
- **变体**：ok（成功）/ warn（警告）/ err（错误）/ info（中性信息）。
- **关键状态**：静态只读。

---

## 解剖 Anatomy

```
● 已签到    ● 待提交    ● 异常    ● 进行中
ok(绿)      warn(橙)    err(红)   info(青雾)
浅语义底 + 同色相文字 + 同色实心圆点
```

**必需元素**：前导圆点（语义色）、文字（同色相）、浅语义底。圆角 full。

---

## 变体 Variants

| 变体 | 圆点 / 文字 | 底色 | 场景 |
|---|---|---|---|
| **ok** | `--success` | `--success-tint` | 已完成 / 通过 |
| **warn** | `--warn` | `--warn-tint` | 待处理 / 临期 |
| **err** | `--danger` | `--danger-tint` | 失败 / 异常 |
| **info** | `--brand-strong` | `--brand-tint` | 进行中 / 中性 |

---

## 状态 States

静态只读。可点筛选标签请用 **Chip**；StatusPill 仅表达状态，不承载交互。

---

## Token 映射

| 设计 token | 亮色 | 暗色 |
|---|---|---|
| `--success` / `--success-tint` | `#1F8F57` / `#E7F4EC` | `#28C26B` / `#14241B` |
| `--warn` / `--warn-tint` | `#B26A12` / `#FBF1E0` | `#D89134` / `#2A2113` |
| `--danger` / `--danger-tint` | `#C23B33` / `#FBECEA` | `#E5564B` / `#2C1715` |
| `--brand-ink` / `--brand-tint` | `#356263` / `#E9F0F0` | `#A8CFCF` / `#1E3233` |

---

## Flutter API

```dart
enum YhStatus { ok, warn, err, info }

class YhStatusPill extends StatelessWidget {
  const YhStatusPill({super.key, required this.label, this.status = YhStatus.info});
}
```

```dart
YhStatusPill(label: '已签到', status: YhStatus.ok);
YhStatusPill(label: '待提交', status: YhStatus.warn);
```

---

## Do & Don't

### ✅ Do
- 语义色含义稳定（绿=好、橙=注意、红=坏、青雾=中性）。
- 文字 ≤ 4 字，配圆点强化状态感。

### ❌ Don't
- 用 StatusPill 做可点筛选（那是 Chip）。
- 仅靠颜色区分（必须配文字 + 圆点形状辅助色盲）。

---

## 可交互样例

[`samples/status-pill.html`](./samples/status-pill.html)

## 无障碍 Accessibility

- 文字承载语义，颜色仅辅助；`Semantics(label:'状态：已签到')`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
