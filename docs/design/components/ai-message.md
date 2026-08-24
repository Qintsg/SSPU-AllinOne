# AIMessage AI 回答气泡

> 工大聚合 AI 助手的回答消息——机器人头像 + 气泡正文 + 来源标。"有出处的 AI"是产品可信内核。

## 概述

- **用途**：AI 问答的助手侧消息（区别于用户气泡）。
- **变体**：text（纯文字）/ with-sources（带 SourceBadge 引用，默认）/ streaming（流式打字中）。
- **关键状态**：streaming（光标闪烁）/ done（带来源）。

---

## 解剖 Anatomy

```
◯  ┌────────────────────────────────┐
🤖 │ 考试安排在「教务 → 考试」查看。      │  ← 气泡（左上角小圆角=指向头像）
   │ ┌──────────────────────────┐    │
   │ │ 📄 FAQ：如何查询考试安排    │    │  ← 内嵌 SourceBadge（来源）
   │ └──────────────────────────┘    │
   └────────────────────────────────┘
```

**必需元素**：机器人头像（青雾实心）、气泡正文。**可选**：SourceBadge 来源行（强烈建议有依据时附上）。

---

## 状态 States

| 状态 | 视觉 |
|---|---|
| **streaming** | 正文末尾闪烁光标，逐字出现 |
| **done** | 完整正文 + 来源标行 |
| **error** | 气泡内提示"回答失败，重试"（danger 文字） |

---

## Token 映射

| 设计 token | 亮色 | 暗色 |
|---|---|---|
| `--brand-strong`（头像底） | `#478384` | `#5C9A9B` |
| `--on-brand`（头像图标） | `#FFFFFF` | `#0A0D12` |
| `--surface` / `--border`（气泡） | `#FFFFFF` / `#D1CEC9` | `#1E2226` / `#353A3F` |
| `--brand-tint` / `--brand-ink`（来源标） | `#E9F0F0` / `#356263` | `#1E3233` / `#A8CFCF` |

---

## Flutter API

```dart
class YhAiMessage extends StatelessWidget {
  const YhAiMessage({super.key, required this.text, this.sources = const [], this.streaming = false});
  // sources: List<YhSourceBadge 数据>；streaming 时显示打字光标。
}
```

```dart
YhAiMessage(
  text: '考试安排可在「教务 → 考试」查看，考前 3 天会推送提醒。',
  sources: [(title: 'FAQ：如何查询考试安排', kind: faq)],
);
```

---

## Do & Don't

### ✅ Do
- 有知识库/文件依据时**必附 SourceBadge**——这是工大聚合可信度的核心。
- 用户气泡靠右、AI 气泡靠左 + 头像，区分清楚。
- 流式回答给打字光标反馈。

### ❌ Don't
- 给凭空生成的内容硬加来源（误导）。
- AI 与用户气泡同色同向（分不清谁说的）。

---

## 可交互样例

[`samples/ai-message.html`](./samples/ai-message.html) — 带来源的 AI 回答。

## 无障碍 Accessibility

- 气泡 `Semantics(label:'AI 助手回答：…，来源：FAQ 如何查询考试安排')`；streaming 用 `liveRegion` 播报增量。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
