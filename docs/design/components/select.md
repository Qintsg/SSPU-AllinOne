# Select 下拉选择

> 从预设选项里单选——外观与 TextField 一致（标签在上 + 控件行），尾随下拉箭头，展开浮层菜单。

## 概述

- **用途**：有限预设项的单选（学期、学院、排序）。选项 ≥ 6 或需搜索时用 Select；2–5 个固定互斥行动就地切换用 Segmented/Radio。作为多字段查询条件且选项由远端动态提供时，可继续使用 Select 保持字段结构、禁用态和键盘路径一致。
- **变体**：single（单选，默认）；compact trigger（仅缩减触发器内边距与箭头，不缩减 48dp 高度）。
- **关键状态**：closed / open / selected / disabled。

---

## 解剖 Anatomy

```
学期                              ← 标签 flabel
┌─────────────────────────────┐
│ 请选择学期                 ⌄ │  ← 触发器（同字段外壳）+ 尾随 chev
└─────────────────────────────┘
   ┌───────────────────────┐
   │ 2025 秋季学期        ✓ │   ← 浮层菜单（选中项右侧勾 + 青雾字）
   │ 2025 春季学期          │
   └───────────────────────┘
```

**布局契约**：触发器复用 `.yh-field .control`，`val` 占满、chev 尾随竖向居中；占位态 `val.placeholder` 用 `--muted`。展开时 chev 旋转 180°、触发器描边青雾，浮层 `box-shadow` 浮起。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **closed** | 同字段 rest；占位 `--muted` |
| **open** | 触发器边框 + chev 转青雾；浮层展开 |
| **selected** | val 显示选中文案；菜单内该项青雾字 + ✓ |
| **disabled** | 不透明度 45% |

> 点击触发器开合、点选项收起、点空白处关闭。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--brand-strong` | `brandStrong` | `0xFF478384` | `0xFF5C9A9B` |
| `--surface` | `surface` | `0xFFFFFFFF` | `0xFF1E2226` |
| `--sunken`（hover） | `sunken` | `0xFFFAFAFA` | `0xFF181B1E` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |
| `--shadow-2` | `elevation2` | `0 4 12 / 12%` | `0 4 12 / 50%` |

---

## Flutter API

```dart
class YhSelect<T> extends StatelessWidget {
  const YhSelect({
    super.key,
    required this.label,
    required this.options,     // List<({T value, String label})>
    required this.value,
    required this.onChanged,
    this.hint = '请选择',
    this.enabled = true,
    this.compact = false,       // 紧凑多列筛选仅压缩横向装饰
  });
  // 触发器 = YhTextField 外壳（只读）+ 尾随箭头；点击弹 YhMenu（自绘浮层）。
}
```

```dart
YhSelect<String>(
  label: '学期',
  hint: '请选择学期',
  options: const [(value:'2025a', label:'2025 秋季学期'), (value:'2025s', label:'2025 春季学期')],
  value: term,
  onChanged: (v) => setState(() => term = v),
);
```

---

## Do & Don't

### ✅ Do
- 选项较多（≥ 6）、文案较长，或属于远端动态查询字段时用 Select。
- 浮层项左文案、右选中勾，命中项青雾高亮。
- 点空白处关闭，避免浮层滞留。
- 多列筛选在紧凑视口可启用 `compact`；触控高度、完整语义标签和浮层文案保持不变。

### ❌ Don't
- 2–5 个固定短行动还用 Select（用 Segmented/Radio 更直接）；远端动态查询字段除外。
- 浮层无最大高度，选项几十个不滚动。

---

## 可交互样例

[`samples/select.html`](./samples/select.html) — 开合 / 选择 / 选中勾，点空白关闭。

## 无障碍 Accessibility

- 触发器 `Semantics(button:true, label:'$label：$当前值')`；浮层项 `inMutuallyExclusiveGroup`，方向键移动 + 回车选中。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.4.0 | 2026-07-30 | 增加紧凑触发器密度，保留 48dp 高度与完整选择语义 |
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 · 复用 .yh-field 外壳 |
