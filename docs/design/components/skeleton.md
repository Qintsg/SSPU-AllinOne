# Skeleton 骨架屏

> 加载占位——用灰块勾勒即将出现的内容轮廓，配微光动画，比转圈更稳、更快感知。

## 概述

- **用途**：内容加载期间的占位（列表、卡片、详情页）。
- **变体**：line（文本行）/ block（图片/卡片块）/ circle（头像，圆角 full）。
- **关键状态**：loading（shimmer 动画）→ 内容就位后替换。

---

## 解剖 Anatomy

```
████████████░░░░░░░       ← line（不同宽度模拟长短文本）
██████████████████
██████░░░░░░░░░░░░░
┌────────────────┐
│                │        ← block（图片/卡片占位）
└────────────────┘
```

**必需元素**：占位块（`--border` 底 + `yh-shimmer` 透明度脉冲动画）。

---

## 状态 States

| 状态 | 行为 |
|---|---|
| **loading** | 占位块 1.5s 透明度脉冲（0.45↔1） |
| **loaded** | 整体替换为真实内容（避免布局跳动——占位尺寸应接近真实） |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--border` | `skeletonBase` | `0xFFD1CEC9` | `0xFF353A3F` |

动画：`@keyframes` 透明度脉冲，时长 1.5s，缓动 `cubic-bezier(.4,0,.2,1)`。

---

## Flutter API

```dart
class YhSkeleton extends StatelessWidget {
  const YhSkeleton.line({this.widthFactor = 1});
  const YhSkeleton.block({this.height = 80});
  const YhSkeleton.circle({this.size = 38});
  // 内部用 AnimatedOpacity / shimmer 包裹占位 Container。
}
```

```dart
Column(children: [
  YhSkeleton.line(widthFactor: 0.7),
  YhSkeleton.line(widthFactor: 0.9),
  YhSkeleton.block(height: 120),
]);
```

---

## Do & Don't

### ✅ Do
- 占位形状/尺寸贴近真实内容，加载完成不跳动。
- 行宽参差（70% / 90% / 50%）更像真实文本。

### ❌ Don't
- 用高对比闪光扫光（晃眼）——清源用低幅透明度脉冲。
- 骨架与真实内容布局差异大（加载完版面突变）。

---

## 可交互样例

[`samples/skeleton.html`](./samples/skeleton.html) — 行 / 块 / 列表行骨架。

## 无障碍 Accessibility

- 容器 `Semantics(label:'加载中', liveRegion:true)`；加载完成移除并播报"加载完成"。
- 尊重 `prefers-reduced-motion`：弱化或停用脉冲。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
