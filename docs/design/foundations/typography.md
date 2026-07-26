# 字体 · Typography

清源使用 **MiSans**（w300–700，已内置）——开源、CJK 覆盖好、可变字重、比 SF Pro / PingFang 更有书卷气。英文与数字回退到系统 San Francisco / Segoe UI。

---

## 1. 字体栈

```css
--font-display: 'MiSans', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
--font-body:    'MiSans', -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
--font-mono:    ui-monospace, 'SF Mono', 'Cascadia Code', Menlo, Consolas, monospace;
```

Flutter：
```dart
const yhFontFamily = 'MiSans';  // 已在 pubspec.yaml 注册
const yhMonoFamily = 'SF Mono';  // iOS 系统自带；Android 回退 Roboto Mono
```

---

## 2. 字阶 · Type scale

**7 级 + 3 个内容变体**——界面字阶从 caption 到 display，feed、reading 与 supporting 分别服务资讯标题、长文和两行摘要。

| 级别 | Size | Line-height | Weight | 用途 | Flutter |
|---|---|---|---|---|---|
| **display** | 36 px | 1.1 | 600 (Semibold) | 页面标题 / 空状态主文案 | `fontSize: 36, height: 1.1, fontWeight: FontWeight.w600` |
| **h1** | 28 px | 1.2 | 600 | 卡片大标题 / 对话框标题 | `28, 1.2, w600` |
| **h2** | 22 px | 1.3 | 500 (Medium) | 分组标题 / List section header | `22, 1.3, w500` |
| **h3** | 18 px | 1.4 | 500 | 小节标题 / 卡片副标题 | `18, 1.4, w500` |
| **body** | 15 px | 1.5 | 400 (Regular) | 正文 / 按钮文字 / 输入框 | `15, 1.5, w400` |
| **feed** | 15 px | 1.45 | 600 | 资讯卡两行标题 | `15, 1.45, w600` |
| **reading** | 15 px | 1.75 | 400 | 邮件、法律和文档类长文阅读 | `15, 1.75, w400` |
| **small** | 13 px | 1.4 | 400 | 辅助文字 / 时间戳 | `13, 1.4, w400` |
| **supporting** | 13 px | 1.65 | 400 | 资讯卡、结果卡两行摘要 | `13, 1.65, w400` |
| **caption** | 11 px | 1.3 | 400 | 提示文案 / 徽标数字 | `11, 1.3, w400` |

**基准**：正文 **15 px**（比旧 Fluent 的 14 提 1px，提升可读性，移动端不显拥挤）。

---

## 3. 字距 · Letter-spacing

**关键规则**：大字收紧、小字放松、**全大写必须加**。

| 情境 | Letter-spacing | 示例 |
|---|---|---|
| Display / H1 (≥28px) | `-0.02em` | 页面标题紧凑有力 |
| H2–H3 (18–22px) | `-0.01em` | 小节标题 |
| Body (15px) | `0` | 正文默认 |
| Small / Caption (≤13px) | `+0.01em` | 辅助文字透气 |
| **全大写（任何尺寸）** | **`+0.06em ~ +0.1em`** | "EAMS" / "FAQ" 徽标 |
| UI 标签 / 按钮 | `+0.02em` | "确认" / "取消" |

Flutter：
```dart
letterSpacing: -0.02 * fontSize,  // display
letterSpacing: 0.06 * fontSize,   // 全大写
```

**反例 ❌**：全大写不加字距——"EAMS" 显得挤、不专业。

---

## 4. 层级用法

### 移动端（宽 ≤ 600dp）

| 场景 | 字阶 | 补充 |
|---|---|---|
| 页面标题（AppBar） | h2 (22px) | 居中 / 可截断 |
| 卡片主标题 | h3 (18px) | 最多两行 |
| 正文 / 表单 | body (15px) | 单行高度 22.5px |
| 长文阅读 | reading (15px) | 单行高度 26.25px |
| 底栏标签 | small (13px) | 配 20×20 图标 |

### 桌面端（宽 > 1200dp）

| 场景 | 字阶 |
|---|---|
| 页面标题 | display (36px) 或 h1 (28px) |
| 侧栏分组 | h3 (18px) |
| 主内容 | body (15px) |
| 元数据 | small (13px) |

**密度不变**：桌面不放大字号，只增加列数与留白——保持信息密度。

---

## 5. 字重用法

MiSans 提供 w300–700，但清源只用 **三档**：

| Weight | 用途 |
|---|---|
| **w400 Regular** | 正文 / 辅助文字 / 输入框 |
| **w500 Medium** | 小节标题 / 已选中的标签 / 强调文本 |
| **w600 Semibold** | 页面标题 / 主按钮文字 / 对话框标题 |

**禁止 w700 Bold**——过重，破坏清透感。w600 已是清源的"最重"。

---

## 6. 行长与折行

- **正文行长**：移动端 90% 屏宽，桌面端 `max-width: 65ch`（约 520–600px）。
- **标题不超 3 行**：超过则截断 + 省略号，或拆分多张卡片。
- **禁用 `text-align: justify`**（两端对齐）——中文/英文混排会产生河流，移动端尤其难看。

Flutter：
```dart
Text(
  title,
  maxLines: 3,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(fontSize: 18, height: 1.4),
)
```

---

## 7. 数字与等宽

**tabular-nums**（表格数字）——数字宽度固定，对齐清爽。

```css
font-variant-numeric: tabular-nums;
```

Flutter：
```dart
fontFeatures: [FontFeature.tabularFigures()],
```

**使用场景**：成绩列表 / 倒计时 / 金额 / 课程节次（"第 3 节" 的 3）。

**等宽字体**（mono）：仅用于代码 / 学号 / MAC 地址 / JSON 日志——不用于 UI 标签。

---

## Do & Don't

### ✅ Do
- 全大写文字（"FAQ" / "GPA" / "EAMS"）加 `+0.06em` 字距——永远。
- 移动端正文 15px，桌面端也是 15px（密度靠列数调，不靠字号）。
- 表格数字、倒计时用 `tabular-nums`，让数字列对齐。

### ❌ Don't
- ❌ 用 w700 Bold——清源最重就是 w600。
- ❌ 标题超 3 行不截断——拥挤且失焦。
- ❌ Display 尺寸（36px+）不加负字距——显松散、不专业。
- ❌ 正文 `text-align: justify`——中英混排产生河流，移动端尤其糟。

---

**下一步** → [间距 · Spacing](./spacing.md)
