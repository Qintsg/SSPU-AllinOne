# 颜色 · Color

清源的颜色体系分六层：**中性色（70–90% 占比）+ 品牌青雾（行动色 #478384）+ 墨蓝结构（图表/深色强调）+ 八业务域分类色 + 状态色 + 效果色（<1%）**。

> 本文件解释颜色语义；[`resources/tokens.json`](../resources/tokens.json) 是唯一机器真源，并由 CI 校验 [`components/samples/_qingyuan.css`](../components/samples/_qingyuan.css) 与 Flutter 映射。改色先改 JSON，再同步说明与镜像。

---

## 1. 中性色 · Neutrals

背景、表面、前景、弱化文本、边框——构成 UI 的骨架。采用**暖灰**（非冷蓝），与品牌青雾形成冷暖对照。

### 亮色模式

| Token | Hex | OKLch | 用途 | WCAG vs `--fg` |
|---|---|---|---|---|
| `--bg` | `#F7F6F5` | `oklch(97% 0.002 60)` | 页面背景 | — |
| `--surface` | `#FFFFFF` | `oklch(100% 0 0)` | 卡片 / 输入框底 | — |
| `--sunken` | `#FAFAFA` | `oklch(98% 0.001 60)` | 内容沉底 / 预览底 | — |
| `--fg` | `#1C1B1A` | `oklch(23% 0.002 60)` | 正文 / 图标 | **基准** |
| `--muted` | `#6B6964` | `oklch(52% 0.004 70)` | 辅助文字 / 占位符 | AA (5.0:1) |
| `--border` | `#D1CEC9` | `oklch(86% 0.004 70)` | 分割线 / 描边 | — |

### 暗色模式

| Token | Hex | OKLch | 用途 |
|---|---|---|---|
| `--bg` | `#14171A` | `oklch(20% 0.006 250)` | 页面背景（非纯黑） |
| `--surface` | `#1E2226` | `oklch(26% 0.006 250)` | 卡片 / 输入框底 |
| `--sunken` | `#181B1E` | `oklch(23% 0.005 250)` | 内容沉底 |
| `--fg` | `#E8E6E3` | `oklch(93% 0.002 70)` | 正文 / 图标（非纯白） |
| `--muted` | `#9A9893` | `oklch(67% 0.004 70)` | 辅助文字 |
| `--border` | `#353A3F` | `oklch(35% 0.008 250)` | 分割线 |

**对比度承诺**：`--fg` on `--surface` ≥ 14:1（亮）、12:1（暗）；`--muted` on `--surface` ≥ 4.5:1。避免纯黑 `#000` / 纯白 `#FFF` 大面积。

---

## 2. 品牌青雾 · Brand (accent · 响应色 #478384)

**行动色**——主按钮、选中态、链接、FAB、底栏高亮。一屏至多用**两次**。

### 亮色模式

| Token | Hex | OKLch | 用途 | 白字对比度 |
|---|---|---|---|---|
| `--brand` | `#6FA3A4` | `oklch(67% 0.04 195)` | 身份点缀（小图标 / 边框 / 亮支） | 2.4:1（不扛白字） |
| `--brand-strong` | `#478384` | `oklch(56% 0.05 195)` | 实色填充 CTA（**响应色**，扛白字） | **4.3:1**（AA Large） |
| `--brand-tint` | `#E9F0F0` | `oklch(95% 0.008 195)` | 选中态浅底 | — |
| `--brand-ink` | `#356263` | `oklch(44% 0.035 195)` | 浅底上的深字 | 7.1:1 on `--brand-tint` |
| `--on-brand` | `#FFFFFF` | — | `--brand-strong` 上的白字 | — |

### 暗色模式

| Token | Hex | 用途 |
|---|---|---|
| `--brand` | `#7FB0B1` | 身份点缀 |
| `--brand-strong` | `#5C9A9B` | 实色填充（暗色下提亮一档） |
| `--brand-tint` | `#1E3233` | 选中态浅底 |
| `--brand-ink` | `#A8CFCF` | 浅底上的浅字 |
| `--on-brand` | `#0A0D12` | `--brand-strong` 上的字（暗色用近黑） |

**单支原则**：青雾是唯一的**行动色**；八业务域色只用于分类标识，不做 CTA。
**对比度提醒**：`--brand-strong` 白字为 4.3:1（AA Large，按钮/≥18px 文字达标）；正文级小白字慎用，必要时压深或改用 `--brand-ink` 配浅底。

---

## 3. 墨蓝结构 · Structural

深色调的**第二支品牌色**——顶栏头图、图表主色、AI 助手气泡。不与青雾在同一组件里同时出现（避免双主色竞争）。

| Token | Hex (亮) | OKLch | 用途 |
|---|---|---|---|
| `--structural` | `#14304D` | `oklch(24% 0.03 240)` | 深色顶栏 / 图表主柱 / AI 用户气泡底 |
| `--structural-fg` | `#FFFFFF` | — | `--structural` 上的白字 (12.5:1 AAA) |

暗色模式：`--structural` → `#2A4A6E`（提亮避免与 `--bg` 融合）。

---

## 4. 八业务域分类色 · Service categories

**语义稳定**——每个域色只用于**小徽标、圆点标签、分类筛选**，不做大面积填充，也不做 CTA。

### 亮色模式

| 域 | Token | Hex | OKLch | 典型场景 |
|---|---|---|---|---|
| 教务 EAMS | `--service-academic` | `#3D7EA6` | `oklch(56% 0.06 235)` | 成绩 / 培养方案 |
| 课程表 | `--service-schedule` | `#6B5B95` | `oklch(48% 0.06 290)` | 课程块 / 空教室 |
| 资讯聚合 | `--service-news` | `#C97D4A` | `oklch(64% 0.10 50)` | 院系新闻 / 公众号 |
| 校园邮箱 | `--service-mail` | `#5C8C6E` | `oklch(60% 0.05 150)` | 收件箱 / 草稿 |
| 财务 | `--service-finance` | `#B85C6A` | `oklch(56% 0.12 15)` | 缴费 / 账单 |
| 体育考勤 | `--service-sports` | `#8A6B3D` | `oklch(52% 0.08 70)` | 跑步记录 / 场馆 |
| 第二课堂 | `--service-secondclass` | `#6A8C5C` | `oklch(60% 0.06 130)` | 活动 / 学分 |
| 快捷入口 | `--service-quicklink` | `#7A7A8C` | `oklch(58% 0.02 270)` | 超星 / OA / 图书馆 |

### 暗色模式（同色相、提亮 10–15%）

每个域色在暗色下走同色相、明度 +10–15% 的变体（如教务 `#3D7EA6` → `#5599C2`），保证 `--surface` 上可读性 ≥ 4.5:1。

**可生长约定**：若新增业务域，从 OKLch 色轮均分未占区间取色（如已占 15°/50°/70°/130°/150°/235°/270°/290°，新域可取 195°(避开品牌青雾)以外区间）。

---

## 5. 状态色 · Semantic

成功 / 警告 / 错误——全局语义，不受业务域覆盖。每个状态配一个浅底 `-tint`（Banner / StatusPill 用）。

### 亮色模式

| 状态 | Token | Hex | 浅底 `-tint` | OKLch | 场景 |
|---|---|---|---|---|---|
| 成功 | `--success` | `#1F8F57` | `#E7F4EC` | `oklch(58% 0.13 155)` | 提交成功 / 完成勾选 |
| 警告 | `--warn` | `#B26A12` | `#FBF1E0` | `oklch(58% 0.11 70)` | 流量提示 / 待处理 |
| 错误 | `--danger` | `#C23B33` | `#FBECEA` | `oklch(54% 0.18 25)` | 校验失败 / 删除确认 |

### 暗色模式（同色相提亮）

| 状态 | Hex | 浅底 `-tint` |
|---|---|---|
| `--success` | `#28C26B` | `#14241B` |
| `--warn` | `#D89134` | `#2A2113` |
| `--danger` | `#E5564B` | `#2C1715` |

---

## 6. 效果色 · Effects (<1%)

渐变、光晕、蒙版——慎用，仅在**有功能含义**时出现（如头图渐变分离层级、加载时微光）。

- **禁止**：装饰性双色渐变背景、无功能的 blob 几何。
- **允许**：`linear-gradient(180deg, var(--structural) 0%, transparent 100%)` 用于顶栏与内容过渡。
- 遮罩：亮 `rgba(0,0,0,.45)`、暗 `rgba(0,0,0,.6)`（Dialog scrim）。

---

## 生成与扩展

### OKLch 优势

所有颜色均用 **OKLch** 定义（`oklch(明度 饱和度 色相)`）——比 HSL 更符合人眼感知，同明度的不同色相亮度一致。品牌青雾色相约 **195°**（青绿），与中性暖灰（60–70°）形成冷暖对照。

**推导暗色变体**：
```
亮色 oklch(L, C, H) → 暗色 oklch(L+8~15%, C×0.9, H)
```

**自动对比度校验**：新颜色加入前，必须在 [OKLch Color Picker & Converter](https://oklch.com/) 验证与 `--fg`/`--surface` 的对比度。

### Flutter 映射

```dart
class YhColors {
  // 中性
  final Color bg, surface, sunken, fg, muted, border;
  // 品牌青雾（响应色 #478384）
  final Color brand, brandStrong, brandTint, brandInk, onBrand;
  // 结构 / 状态
  final Color structural, structuralFg, success, warn, danger;
  // 域色（可增长）
  final Color serviceAcademic, serviceSchedule, serviceNews, serviceMail,
      serviceFinance, serviceSports, serviceSecondclass, serviceQuicklink;

  // 构造函数接收 Brightness，返回亮/暗两套
  YhColors.of(Brightness b) :
    bg          = b == Brightness.light ? const Color(0xFFF7F6F5) : const Color(0xFF14171A),
    surface     = b == Brightness.light ? const Color(0xFFFFFFFF) : const Color(0xFF1E2226),
    sunken      = b == Brightness.light ? const Color(0xFFFAFAFA) : const Color(0xFF181B1E),
    fg          = b == Brightness.light ? const Color(0xFF1C1B1A) : const Color(0xFFE8E6E3),
    muted       = b == Brightness.light ? const Color(0xFF6B6964) : const Color(0xFF9A9893),
    border      = b == Brightness.light ? const Color(0xFFD1CEC9) : const Color(0xFF353A3F),
    brand       = b == Brightness.light ? const Color(0xFF6FA3A4) : const Color(0xFF7FB0B1),
    brandStrong = b == Brightness.light ? const Color(0xFF478384) : const Color(0xFF5C9A9B),
    brandTint   = b == Brightness.light ? const Color(0xFFE9F0F0) : const Color(0xFF1E3233),
    brandInk    = b == Brightness.light ? const Color(0xFF356263) : const Color(0xFFA8CFCF),
    onBrand     = b == Brightness.light ? const Color(0xFFFFFFFF) : const Color(0xFF0A0D12),
    success     = b == Brightness.light ? const Color(0xFF1F8F57) : const Color(0xFF28C26B),
    warn        = b == Brightness.light ? const Color(0xFFB26A12) : const Color(0xFFD89134),
    danger      = b == Brightness.light ? const Color(0xFFC23B33) : const Color(0xFFE5564B),
    structural  = b == Brightness.light ? const Color(0xFF14304D) : const Color(0xFF2A4A6E),
    structuralFg = const Color(0xFFFFFFFF),
    serviceAcademic = b == Brightness.light ? const Color(0xFF3D7EA6) : const Color(0xFF5599C2),
    serviceSchedule = b == Brightness.light ? const Color(0xFF6B5B95) : const Color(0xFF9486C0),
    serviceNews = b == Brightness.light ? const Color(0xFFC97D4A) : const Color(0xFFE0995F),
    serviceMail = b == Brightness.light ? const Color(0xFF5C8C6E) : const Color(0xFF7DB091),
    serviceFinance = b == Brightness.light ? const Color(0xFFB85C6A) : const Color(0xFFD67D8A),
    serviceSports = b == Brightness.light ? const Color(0xFF8A6B3D) : const Color(0xFFB08E5C),
    serviceSecondclass = b == Brightness.light ? const Color(0xFF6A8C5C) : const Color(0xFF8DAF7F),
    serviceQuicklink = b == Brightness.light ? const Color(0xFF7A7A8C) : const Color(0xFF9C9CAE);

  static Color accentForService(String id, Brightness b) {
    final c = YhColors.of(b);
    switch (id) {
      case 'academic': return c.serviceAcademic;
      case 'schedule': return c.serviceSchedule;
      case 'news': return c.serviceNews;
      case 'mail': return c.serviceMail;
      case 'finance': return c.serviceFinance;
      case 'sports': return c.serviceSports;
      case 'secondclass': return c.serviceSecondclass;
      case 'quicklink': return c.serviceQuicklink;
      default: return c.muted;
    }
  }
}
```

注册见 [`tokens.md`](./tokens.md)（`YhTheme extends ThemeExtension`）。

---

## Do & Don't

### ✅ Do
- 行动色（青雾）一屏至多两次——一个主 CTA + 一个选中态，或一个 FAB + 一个底栏高亮。
- 域色只做**分类标识**——小圆点、侧边色块、筛选 chip，不做按钮填充。
- 小字图标用 `--brand-strong`/`--brand-ink` 而非浅支 `--brand`，保证可读性。
- 状态用「语义色 + 文字 + 形状」三重编码，照顾色盲。

### ❌ Don't
- ❌ 同一屏幕同时用 `--brand`（青雾）和 `--structural`（墨蓝）做 CTA——单一行动色原则。
- ❌ 把域色（如教务青 `--service-academic`）当作行动色滥用——它不是 CTA，只是分类。
- ❌ 背景用装饰性渐变（紫→蓝、粉→橙）——无功能含义的渐变是 AI slop 特征。
- ❌ 硬编码 hex——全部走 token (`var(--brand)` / `yhColors.brand`)，方便全局换色。

---

**下一步** → [字体 · Typography](./typography.md)
