# CourseBlock 课程块

> 课表网格里的单节课方块——课程名 + 教室 + 时段，整块青雾浅底。课表页的最小单元。

## 概述

- **用途**：周课表 / 日课表网格中的一节课。
- **变体**：default（青雾）/ domain-colored（按课程类别用业务域色）/ empty（空教室占位）。
- **关键状态**：rest / ongoing（当前进行中，加边框高亮）/ conflict（冲突，红описание）。

---

## 解剖 Anatomy

```
╭───────────────╮
│ 数据结构        │  ← 课程名 b
│ 教三-401        │  ← 教室 / 教师 span
│ 14:00–15:40     │
╰───────────────╯
 整块 --brand-tint（不用左色条，避开 AI-slop 形态）
```

**必需元素**：课程名；教室/时段。整块用浅色底（默认 `--brand-tint`），文字 `--brand-ink`。

---

## 变体 Variants

| 变体 | 视觉 | 用途 |
|---|---|---|
| **default** | `--brand-tint` 底 | 普通课 |
| **domain-colored** | 业务域 tint（按学科） | 用颜色区分课程类别 |
| **ongoing** | 加 1.5px `--brand-strong` 实边框 | 当前正在上的课 |
| **empty** | 虚线描边 + `--muted` "空" | 空教室/空档 |

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **rest** | 浅底块 |
| **ongoing** | 实边框高亮 |
| **conflict** | `--danger-tint` 底 + 角标"冲突" |

---

## Token 映射

| 设计 token | 亮色 | 暗色 |
|---|---|---|
| `--brand-tint` / `--brand-ink` | `#E9F0F0` / `#356263` | `#1E3233` / `#A8CFCF` |
| `--brand-strong`（ongoing 边框） | `#478384` | `#5C9A9B` |
| 业务域色 | 见 foundations/color.md 八业务域 | 同 |

---

## Flutter API

```dart
class YhCourseBlock extends StatelessWidget {
  const YhCourseBlock({super.key, required this.name, this.room, this.time, this.accent, this.ongoing = false, this.onTap});
  // accent: 业务域色（可选）；ongoing 加高亮边框。
}
```

```dart
YhCourseBlock(name: '数据结构', room: '教三-401', time: '14:00–15:40', ongoing: true);
```

---

## Do & Don't

### ✅ Do
- 整块用浅色底，文字用同色相深字（可读）。
- 用业务域色区分类别时保持低饱和 tint。
- ongoing 用边框高亮而非闪烁。

### ❌ Don't
- 用左色条 + 圆角卡（AI-slop 形态）——整块上色即可。
- 块内塞过多文字（课程名 + 教室 + 时段足矣）。

---

## 可交互样例

[`samples/course-block.html`](./samples/course-block.html) — default / ongoing / 空教室。

## 无障碍 Accessibility

- `Semantics(button:true, label:'数据结构，教三-401，14:00 到 15:40，进行中')`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
