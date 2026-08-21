# Banner 横幅提示

> 行内的持续性提示条——不打断操作，常驻于内容区顶部。四种语义：信息 / 成功 / 警告 / 错误。

## 概述

- **用途**：页面/区块级的持续提示（数据本地、维护通知、表单错误汇总）。
- **变体**：info / success / warn / danger。
- **关键状态**：static（可带关闭按钮）。

---

## 解剖 Anatomy

```
┌──────────────────────────────────────┐
│ ⓘ  数据仅保留在本地设备，不会上传服务器  │  ← 图标 + 文本，浅语义底
└──────────────────────────────────────┘
```

**必需元素**：语义图标、文本。**可选**：行动链接、关闭 ×。

---

## 变体 Variants

| 变体 | 底色 | 文字/图标 | 用途 |
|---|---|---|---|
| **info** | `--brand-tint` | `--brand-ink` | 中性提示 |
| **success** | `--success-tint` | `--success` | 操作成功的持续确认 |
| **warn** | `--warn-tint` | `--warn` | 需注意但不阻断 |
| **danger** | `--danger-tint` | `--danger` | 错误汇总 / 阻断提示 |

---

## 状态 States

持续展示。可选关闭按钮（关闭后本会话不再出现）。与 Toast 区别：**Banner 常驻、Toast 短暂自动消失**。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-tint` / `--brand-ink` | brandTint / brandInk | `#E9F0F0` / `#356263` | `#1E3233` / `#A8CFCF` |
| `--success(-tint)` | success | `#1F8F57` / `#E7F4EC` | `#28C26B` / `#14241B` |
| `--warn(-tint)` | warn | `#B26A12` / `#FBF1E0` | `#D89134` / `#2A2113` |
| `--danger(-tint)` | danger | `#C23B33` / `#FBECEA` | `#E5564B` / `#2C1715` |

---

## Flutter API

```dart
enum YhBannerKind { info, success, warn, danger }

class YhBanner extends StatelessWidget {
  const YhBanner({super.key, required this.text, this.kind = YhBannerKind.info, this.leadingIcon, this.denseLeading = false, this.action, this.onClose});
}
```

`denseLeading` 只用于高度受限但仍需保留 live-region 反馈的紧凑状态条；它收紧图标与正文的首行对齐，不改变最小触控目标或语义。

```dart
YhBanner(text: '数据仅保留在本地设备，不会上传服务器');
YhBanner(text: '缴费成功，电子票据已生成', kind: YhBannerKind.success);
YhBanner(text: '今晚 23:00–24:00 系统维护', kind: YhBannerKind.warn);
```

---

## Do & Don't

### ✅ Do
- 语义色 = 浅底 + 同色相深字（克制，不刺眼）。
- 持续性提示用 Banner，瞬时反馈用 Toast。

### ❌ Don't
- 用实心高饱和底（像广告）。
- 一屏堆多条 Banner（信息过载）。

---

## 可交互样例

[`samples/banner.html`](./samples/banner.html) — 四语义。

## 无障碍 Accessibility

- danger/warn 用 `Semantics(liveRegion:true)` 即时播报；图标含义勿仅靠颜色（配文字）。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.4.1 | 2026-08-03 | 补充 `denseLeading` 紧凑状态条契约，用于校历/PDF 等保留正文的操作反馈 |
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
