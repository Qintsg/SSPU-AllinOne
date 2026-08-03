# Dialog 对话框

> 需要用户决策的模态浮层——确认删除、二次确认、关键表单。半透明遮罩聚焦，居中面板承载标题/正文/操作。

## 概述

- **用途**：阻断式确认 / 输入（删除确认、退出登录、关键选择）。
- **变体**：confirm（标题 + 正文 + 双操作）/ form（含输入）/ alert（单操作告知）。
- **关键状态**：enter（遮罩淡入 + 面板缩放进入）/ visible / exit。

---

## 解剖 Anatomy

```
░░░░░░░░░░░░░░░░░░░░░░░░  ← 遮罩 rgba 半透明，点击可关（非危险操作）
░  ┌──────────────────┐  ░
░  │ 桌面窗口           │  ← 可选 eyebrow，说明决策上下文
░  │ 删除该课程？       │  ← h3 标题
░  │ 此操作不可撤销…    │  ← p 正文（--muted）
░  │        [取消][删除] │  ← acts 右对齐
░  └──────────────────┘  ░
```

**必需元素**：遮罩、面板（标题 + 操作）。**可选**：正文、表单、关闭 ×。

---

## 状态 States

| 阶段 | 行为 |
|---|---|
| **enter** | 遮罩淡入 + 面板 `scale(0.96→1)` + 淡入 |
| **visible** | 焦点陷入面板（Tab 不逃出）；Esc 关闭（非危险时） |
| **exit** | 反向淡出 |

主操作放右、危险操作用 `danger` 按钮；取消放左为 secondary/text。低于 compact 断点且操作较多时，可启用整行纵向操作区；DOM、键盘与视觉顺序必须一致。不可被系统返回中断的关键任务使用 `canPop: false`，并始终提供显式取消或恢复路径。

---

## Token 映射

| 设计 token | `YhTheme` 字段 | 亮色 | 暗色 |
|---|---|---|---|
| 遮罩 | `scrim` | `rgba(0,0,0,.45)` | `rgba(0,0,0,.6)` |
| `--surface` | surface | `#FFFFFF` | `#1E2226` |
| `--radius-l` | radiusLarge | `24.0` | `24.0` |
| `--shadow-3` | elevation3 | `0 8 28 / 16%` | `0 8 28 / 60%` |

---

## Flutter API

```dart
final ok = await YhDialog.confirm(
  context,
  title: '删除该课程？',
  message: '此操作不可撤销，删除后需重新导入。',
  confirmText: '删除',
  danger: true,
);

await YhDialog.show<void>(
  context,
  barrierDismissible: false,
  canPop: false,
  builder: (_) => YhDialog(
    eyebrow: '桌面窗口',
    title: '关闭应用？',
    content: const Text('完成前保留当前页面。'),
    stackActionsOnCompact: true,
    actions: actions,
  ),
);

YhDialog(
  eyebrow: '外部 PDF',
  title: '在外部应用打开校历？',
  headerInset: context.yhTheme.spacing.l,
  titleStyle: context.yhTheme.typography.h3,
  content: const Text('离开应用后的本地保护边界说明。'),
  actions: actions,
);
```

`headerInset` 与 `titleStyle` 是受控的阅读层级参数，仅用于外部边界等已冻结的紧凑确认稿；取值必须来自 `YhTheme` token，业务页不得用它们构造任意弹窗视觉。

---

## Do & Don't

### ✅ Do
- 标题用疑问句/动词短语，正文说明后果。
- 危险确认按钮用 danger；焦点默认落在安全项（取消）。
- 遮罩点击关闭仅限非危险对话框。

### ❌ Don't
- 用 Dialog 做纯告知（那用 Toast/Banner）。
- 叠多层 Dialog（弹窗套弹窗）。
- 危险操作把"删除"设为默认聚焦项。

---

## 可交互样例

[`samples/dialog.html`](./samples/dialog.html) — 确认对话框（静态展开 + 触发演示）。

## 无障碍 Accessibility

- `role=dialog` + `aria-modal`；焦点陷入与归还；Esc 关闭；标题作为 `aria-labelledby`。

---

## 变更记录

| 版本 | 日期 | 变更内容 |
|---|---|---|
| 0.4.1 | 2026-08-03 | 记录外部边界确认所需的 token 化标题间距与样式参数 |
| 0.1.0 | 2026-06-16 | 初始规格 · 响应色 #478384 |
| 0.4.0 | 2026-07-29 | 增加 eyebrow、紧凑纵向操作区与系统返回锁定契约 |
