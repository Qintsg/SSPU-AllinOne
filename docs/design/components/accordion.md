# Accordion 折叠面板

> 标题行点击展开/收起内容——常见问题、分组设置、详情折叠。收纳长内容，降低首屏密度。

## 概述

- **用途**：FAQ、分组表单、可折叠详情。
- **变体**：single（同时只展开一项）/ multi（可多项同时展开，默认）。
- **关键状态**：collapsed / expanded。

---

## 解剖 Anatomy

```
┌──────────────────────────────┐
│ 如何查询考试安排？        ⌄   │  ← head：标题 + chevron
├──────────────────────────────┤
│ 在「教务 → 考试」查看…         │  ← body（展开时高度展开）
└──────────────────────────────┘
```

**必需元素**：head（标题 + chevron）、body（可折叠内容）。多项堆叠用 1px 分隔。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **collapsed** | body 高度 0；chevron 朝下 |
| **expanded** | body 展开（`max-height` 过渡）；chevron 旋转 180° + 转青雾 |
| **hover head** | 可加浅底（可选） |

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| `--surface` | `surface` | `0xFFFFFFFF` | `0xFF1E2226` |
| `--border` | `border` | `0xFFD1CEC9` | `0xFF353A3F` |
| `--brand-strong` | `brandStrong`（展开 chevron） | `0xFF478384` | `0xFF5C9A9B` |
| `--muted` | `muted`（正文 / 收起 chevron） | `0xFF6B6964` | `0xFF9A9893` |

---

## Flutter API

```dart
class YhAccordion extends StatelessWidget {
  const YhAccordion({super.key, required this.items, this.multi = true});
  // items: List<({String title, Widget body})>；展开态在内部 State 管理。
}
```

```dart
YhAccordion(items: [
  (title: '如何查询考试安排？', body: Text('在「教务 → 考试」查看。')),
  (title: '校园卡丢了怎么办？', body: Text('在「服务 → 校园卡」挂失并补办。')),
]);
```

---

## Do & Don't

### ✅ Do
- chevron 旋转给出明确开合反馈，配 `max-height` 过渡。
- FAQ 用 multi，单选设置组用 single。

### ❌ Don't
- 折叠里再塞折叠（嵌套层级过深）。
- 展开/收起无动画（生硬跳变）。

---

## 可交互样例

[`samples/accordion.html`](./samples/accordion.html) — 点标题行展开/收起。

## 无障碍 Accessibility

- head `Semantics(button:true, expanded:..., label:title)`；展开内容与 head 关联。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
