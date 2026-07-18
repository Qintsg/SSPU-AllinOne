# Button 按钮

> 最常用的行动触发器——清源按钮用 16px 柔圆角 + 青雾响应色 `#478384` + 明确的五态反馈。

## 概述

- **用途**：触发即时行动（提交、确认、导航）。
- **变体**：primary（实心）/ secondary（描边）/ text（纯文本）/ danger（危险）。
- **关键状态**：rest / hover / pressed / focus / disabled。

---

## 解剖 Anatomy

```
┌─────────────────────────────────┐
│  [icon] 8  Label  8  [trailing] │  ← 容器 h=48dp, radius=16
└─────────────────────────────────┘
   ↑       ↑    ↑    ↑      ↑
  前图    间距  文本 间距    尾图（可选）
  20×20         w500         20×20
```

**必需元素**：容器（高 48dp 移动 / 40dp 桌面，圆角 16px）、文本标签（MiSans w500 15px，letter-spacing 0.01em）。
**可选元素**：前置 / 尾随图标（20×20）。**最小宽度** 96px。

---

## 变体 Variants

| 变体 | 视觉 | token | 用途 |
|---|---|---|---|
| **Primary** | 青雾实心 + 白字 | `bg: --brand-strong` (#478384) · `fg: --on-brand` | 主要行动（一屏至多 1 个） |
| **Secondary** | 1.5px 青雾边框 + 青雾字 + 透明底 | `border: --brand` · `fg: --brand-strong` | 次要行动（取消 / 返回） |
| **Text** | 无容器，仅青雾字（hover 下划线） | `fg: --brand-strong` | 低优先级（了解更多 / 跳过） |
| **Danger** | 红实心 + 白字 | `bg: --danger` | 破坏性行动（删除） |

---

## 状态 States

| 状态 | Primary | Secondary | Text |
|---|---|---|---|
| **rest** | 青雾填充 + 白字 | 青雾边框 + 青雾字 | 青雾字 无装饰 |
| **hover** | `brightness(0.95)` | 浅青雾底 `--brand` 10% | + 下划线 |
| **pressed** | `brightness(0.9)` + `scale(0.98)` | 浅青雾底 16% + `scale(0.98)` | `brightness(0.9)` |
| **focus** | 外轮廓 2px `--brand` | 外轮廓 2px `--brand` | 外轮廓 2px `--brand` |
| **disabled** | 不透明度 40% + `not-allowed` | 同左 | 同左 |

**动效**：状态切换 120ms `cubic-bezier(0.33, 0, 0.2, 1)`。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand` | `brandPrimary` | `0xFF6FA3A4` | `0xFF7FB0B1` |
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--on-brand` | `onBrand` | `0xFFFFFFFF` | `0xFF0A0D12` |
| `--radius-m` | `radiusMedium` | `16.0` | `16.0` |
| `--space-m` | `spacingMedium` | `16.0` | `16.0` |

---

## Flutter API

```dart
enum YhButtonVariant { primary, secondary, text, danger }

class YhButton extends StatefulWidget {
  const YhButton({
    super.key,
    required this.label,
    this.onTap,
    this.variant = YhButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.disabled = false,
    this.minWidth = 96.0,
    this.height = 48.0,
  });

  final String label;
  final VoidCallback? onTap;
  final YhButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool disabled;
  final double minWidth;
  final double height;

  @override
  State<YhButton> createState() => _YhButtonState();
}
// _YhButtonState：MouseRegion(hover) + GestureDetector(pressed) +
// AnimatedScale(0.98) + Container(decoration: 取自 yh.brandStrong/brand)。
// 颜色按 variant + disabled + hover/pressed 叠加，全部读 YhTheme，零裸值。
```

```dart
// 用法
YhButton(label: '提交申请', onTap: submit);
YhButton(label: '取消', variant: YhButtonVariant.secondary, leadingIcon: Icons.close);
YhButton(label: '了解更多', variant: YhButtonVariant.text);
YhButton(label: '删除', variant: YhButtonVariant.danger, onTap: confirmDelete);
YhButton(label: '不可用', disabled: true);
```

---

## Do & Don't

### ✅ Do
- 文案用动词（"提交申请""取消订单"），不用"确定"这种模糊词。
- 一屏一主：primary 至多 1 个，其余降级 secondary / text。
- 状态可感知；禁用时 `onTap` 不触发、指针 `forbidden`。

### ❌ Don't
- 文本溢出不截断（应 `TextOverflow.ellipsis`）。
- secondary 边框 < 1.5px（高 DPI 会消失）。
- primary 内再嵌 primary。

---

## 可交互样例

[`samples/button.html`](./samples/button.html) — 四变体 + 全状态 + 亮/暗切换。

## 无障碍 Accessibility

- 触控区域 48×48dp（已满足）；Tab 聚焦 + Enter/Space 触发。
- 对比度：白字 / `#478384` ≈ 4.3:1（AA Large）；青雾字 / 白底 ≈ 4.8:1（AA）。
- `Semantics(button: true, label: label, enabled: !disabled)`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.2.0 | 2026-06-16 | 响应色改 #478384 · 新增 danger 变体 · 接入共享样例 |
| 0.1.0 | 2026-06-16 | 初始规格 |
