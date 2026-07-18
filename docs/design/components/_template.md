# [组件名] · ComponentName

> **本文件是组件规格模板**——每个组件规格都按此结构填写，保证文档质量与可实现性。

## 概述

- **用途**：一句话说明组件解决什么问题。
- **变体**：列出主要变体（如 primary / secondary / text 按钮）。
- **关键状态**：rest / hover / pressed / focus / disabled。

---

## 解剖 Anatomy

用标注图或文字描述组件的组成部分：

```
┌─────────────────────────────┐
│  [icon]  Label  [trailing]  │  ← 容器
└─────────────────────────────┘
   ↑       ↑         ↑
  前图    文本      尾图（可选）
```

**必需元素**：容器（Container）、文本标签（Label）。
**可选元素**：前置图标（Leading icon）、尾随元素（Trailing）。

---

## 变体 Variants

### 变体 A（如 primary）
- **视觉**：实色填充 + 白字
- **用途**：主要行动
- **token**：`bg: --brand-strong`（#478384）, `fg: --on-brand`

### 变体 B（如 secondary）
- **视觉**：描边 + 品牌色字
- **token**：`border: --brand`, `fg: --brand-strong`

### 变体 C（如 text）
- **视觉**：无容器，仅文本
- **token**：`fg: --brand-strong`

---

## 状态 States

| 状态 | 视觉变化 | token / 样式 |
|---|---|---|
| **rest** | 默认外观 | 见变体定义 |
| **hover** | 容器色加深 5% | `filter: brightness(0.95)` |
| **pressed** | 容器加深 10% + 轻微缩放 | `brightness(0.9)`, `scale(0.98)` |
| **focus** | 外轮廓 2px 品牌色 | `outline: 2px solid --brand` |
| **disabled** | 不透明度 40% + 指针禁用 | `opacity: 0.4`, `cursor: not-allowed` |

**动效**：状态切换 150ms `cubic-bezier(0.4, 0, 0.2, 1)`。

---

## Token 映射

| 设计 token | Flutter `YhTheme` 字段 | 亮色默认值 | 暗色默认值 |
|---|---|---|---|
| `--brand` | `brandPrimary` | `Color(0xFF6FA3A4)` | `Color(0xFF7FB0B1)` |
| `--brand-strong` | `brandStrong` | `Color(0xFF478384)` | `Color(0xFF5C9A9B)` |
| `--brand-tint` | `brandTint` | `Color(0xFFE9F0F0)` | `Color(0xFF1E3233)` |
| `--brand-ink` | `brandInk` | `Color(0xFF356263)` | `Color(0xFFA8CFCF)` |
| `--on-brand` | `onBrand` | `Color(0xFFFFFFFF)` | `Color(0xFF0A0D12)` |
| `--radius-m` | `radiusMedium` | `16.0` | `16.0` |
| `--space-m` | `spacingMedium` | `16.0` | `16.0` |
| `--fg` | `foreground` | `Color(0xFF1C1B1A)` | `Color(0xFFE8E6E3)` |

---

## Flutter API

### 构造函数

```dart
class YhComponentName extends StatelessWidget {
  const YhComponentName({
    super.key,
    required this.label,
    this.onTap,
    this.variant = Variant.primary,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Variant variant;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final yh = Theme.of(context).extension<YhTheme>()!;
    // ... 实现
  }
}
```

### 用法示例

```dart
YhComponentName(label: '确认', onTap: () {});
YhComponentName(label: '取消', variant: Variant.secondary);
YhComponentName(label: '不可用', disabled: true);
```

---

## Do & Don't

### ✅ Do
- 文案用动词，状态可感知，对比度合规（白字在 `#478384` 上 ≈ 4.3:1，AA Large）。

### ❌ Don't
- 一屏多个 primary；禁用态仍可交互；文本溢出不截断。

---

## 可交互样例

打开 [`samples/component-name.html`](./samples/component-name.html) 查看真实视觉 + 全状态（亮/暗双主题）。
样例只写组件标记，样式与交互来自共享的 [`samples/_qingyuan.css`](./samples/_qingyuan.css) + [`samples/_qingyuan.js`](./samples/_qingyuan.js)。

---

## 无障碍 Accessibility

- 最小触控区域 48×48dp；键盘可聚焦 + Enter/Space 触发；`Semantics(...)` 标注语义与状态。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.2.0 | 2026-06-16 | 响应色统一 #478384 · 接入共享样例样式 |
