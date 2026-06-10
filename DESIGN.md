# DESIGN.md — Fluent 2 设计系统(Flutter 实现指南)

> 本文档定义了在 Flutter 应用中落地 Microsoft **Fluent 2** 设计系统的规范:设计原则、设计令牌(Design Tokens)、Flutter 工程架构、明暗主题、组件规范与无障碍要求。
>
> 它既是设计与开发协作的契约,也是代码评审时的依据。所有 UI 改动应可追溯到本文档中的某一条令牌或规范。

---

## 目录

1. [概述](#1-概述)
2. [设计原则](#2-设计原则)
3. [设计令牌体系](#3-设计令牌体系)
4. [Flutter 架构实现](#4-flutter-架构实现)
5. [明暗主题](#5-明暗主题)
6. [组件规范](#6-组件规范)
7. [无障碍](#7-无障碍)
8. [工程约定](#8-工程约定)
9. [与第三方包的关系](#9-与第三方包的关系)
10. [维护与变更流程](#10-维护与变更流程)

---

## 1. 概述

### 1.1 目标

- 在 Flutter 中以**令牌驱动(token-driven)**的方式实现 Fluent 2,杜绝硬编码的颜色值、像素值与字号。
- 保证 Light / Dark 主题、品牌换色、密度调整可以**集中修改、全局生效**。
- 让设计稿(Figma Fluent 2 UI Kit)与代码使用**同一套语义命名**,降低设计-开发的沟通成本。

### 1.2 适用范围

- 适用于跨平台 Flutter 应用(iOS / Android / Web / Desktop)。
- 采用外部 `fluent_ui` 承载可见 Fluent 控件与主题运行时,通过 `FluentThemeData.extensions` 注入兼容 Fluent 2 令牌,页面统一从 `lib/design/fluent_ui.dart` 使用外部 Fluent 控件、语义图标 facade 和项目业务组合组件。
- 移动端字体回退到系统字体(Android 用 Roboto,iOS 用 SF Pro);桌面/Web 优先 Segoe UI,缺失时回退系统字体。

### 1.3 术语

| 术语                      | 含义                                                         |
| ------------------------- | ------------------------------------------------------------ |
| Global Token(全局令牌)    | 原始值,如 `grey[16]`、`#0F6CBD`、`spacing 12`,无语义。       |
| Alias Token(别名令牌)     | 带语义的令牌,如 `neutralForeground1`、`brandBackgroundHover`,引用全局令牌。 |
| Component Token(组件令牌) | 组件维度的映射,如 `button.primary.fill.rest`。               |
| Type Ramp(字阶)           | Fluent 2 规定的一组带语义角色的文本样式。                    |
| Ramp(色阶/比例阶梯)       | 一组按规律递进的值序列(颜色、间距、阴影)。                   |

> **取值唯一真源(Source of Truth)**:颜色与令牌的精确数值以官方 `@fluentui/tokens` 包及 Fluent 2 Figma UI Kit 为准。本文给出的十六进制值为**对齐用参考值**,落地前应与官方令牌核对一次并在 `tokens/` 目录固化。

---

## 2. 设计原则

Fluent 2 围绕五个基础要素构建,Flutter 落地时对应如下:

| 原则               | 含义                       | Flutter 落地要点                                             |
| ------------------ | -------------------------- | ------------------------------------------------------------ |
| **Light(光)**      | 用明暗与高亮引导注意力     | 用 `elevation` 与 `brand` 高亮态区分焦点,避免靠纯色块堆叠。  |
| **Depth(深度)**    | 通过分层、阴影建立空间层级 | 阴影只走 `FluentElevation` 令牌,禁止自定义 `BoxShadow`。     |
| **Motion(动效)**   | 转场自然、有目的性         | 时长/曲线只取 `FluentMotion` 令牌,默认 `durationNormal + curveEasyEase`。 |
| **Material(材质)** | 半透明、亚克力等材质感     | 移动端克制使用模糊;面板/弹层可用低强度遮罩与背景虚化。       |
| **Scale(适配)**    | 一套设计跨设备一致         | 同一套令牌,通过密度与断点适配不同尺寸,不为单端做特例。       |

通用准则:

- **令牌优先**:任何颜色、间距、圆角、字体都必须来自令牌。代码评审中出现裸值即视为缺陷。
- **语义优先**:使用 `neutralForeground1` 而非 `grey[16]`;使用别名令牌而非全局令牌。
- **左对齐为默认**:LTR 语言正文默认左对齐;长段落禁止居中或两端对齐。
- **克制强调**:一个视图内不堆叠多个高强调元素;一屏一般只有一个主操作(Primary)。

---

## 3. 设计令牌体系

### 3.1 令牌分层

```
Global Tokens   →   Alias Tokens   →   Component Tokens
(原始值)            (语义)             (组件映射)
grey[16]            neutralForeground1  button.primary.fill.rest
#0F6CBD             brandBackground     input.border.focus
spacing 12          spacingHorizontalM  card.padding
```

**规则**:UI 代码只允许引用 **Alias / Component 令牌**;Global 令牌仅在令牌定义文件内部使用。

### 3.2 颜色

Fluent 2 定义三组色板:**Neutral(中性)**、**Brand(品牌)**、**Shared / Status(共享/状态)**。

#### 3.2.1 中性色 — 别名令牌(Light / Dark 参考值)

中性色承载表面、文本与描边,**必须随明暗主题切换**。

| 别名令牌                    | 用途            | Light     | Dark      |
| --------------------------- | --------------- | --------- | --------- |
| `neutralBackground1`        | 主表面/页面底色 | `#FFFFFF` | `#292929` |
| `neutralBackground2`        | 次级表面        | `#FAFAFA` | `#1F1F1F` |
| `neutralBackground3`        | 卡片/分区底     | `#F5F5F5` | `#141414` |
| `neutralBackgroundCanvas`   | 应用画布背景    | `#F0F0F0` | `#0A0A0A` |
| `neutralForeground1`        | 主文本/图标     | `#242424` | `#FFFFFF` |
| `neutralForeground2`        | 次级文本        | `#424242` | `#D6D6D6` |
| `neutralForeground3`        | 占位/弱文本     | `#616161` | `#ADADAD` |
| `neutralForegroundDisabled` | 禁用文本        | `#BDBDBD` | `#5C5C5C` |
| `neutralStroke1`            | 默认描边        | `#D1D1D1` | `#666666` |
| `neutralStroke2`            | 弱描边          | `#E0E0E0` | `#525252` |
| `neutralStrokeDivider`      | 分割线          | `#EBEBEB` | `#3D3D3D` |

#### 3.2.2 品牌色 — Brand Ramp

默认品牌色为 Fluent 通信蓝(Communication Blue),色阶 `brand[10] → brand[160]`,主值 `brand[80] = #0F6CBD`。

参考色阶(换色时通过工具重新生成整条 ramp,不要手改单值):

| 阶          | 值        | 阶           | 值        |
| ----------- | --------- | ------------ | --------- |
| `brand[10]` | `#061724` | `brand[90]`  | `#2886DE` |
| `brand[20]` | `#082338` | `brand[100]` | `#479EF5` |
| `brand[40]` | `#0C3B5E` | `brand[110]` | `#62ABF5` |
| `brand[60]` | `#0F548C` | `brand[130]` | `#96C6FA` |
| `brand[70]` | `#115EA3` | `brand[150]` | `#CFE4FA` |
| `brand[80]` | `#0F6CBD` | `brand[160]` | `#EBF3FC` |

品牌别名令牌(从 ramp 派生,带交互态):

| 别名令牌                  | Light 取值   | 说明             |
| ------------------------- | ------------ | ---------------- |
| `brandBackground`         | `brand[80]`  | 主操作填充(Rest) |
| `brandBackgroundHover`    | `brand[70]`  | 悬停             |
| `brandBackgroundPressed`  | `brand[60]`  | 按下             |
| `brandBackgroundSelected` | `brand[60]`  | 选中             |
| `brandForeground1`        | `brand[80]`  | 品牌文本/图标    |
| `brandForeground2`        | `brand[70]`  | 品牌文本悬停     |
| `brandStroke1`            | `brand[80]`  | 品牌描边         |
| `brandStroke2`            | `brand[140]` | 弱品牌描边       |

> Dark 主题下品牌别名整体上移约一阶(更亮),由生成器统一产出 light/dark 两套。

#### 3.2.3 状态色 — Shared / Status

| 语义                                      | 角色       | Light 参考值          |
| ----------------------------------------- | ---------- | --------------------- |
| `statusSuccessForeground` / `…Background` | 成功(绿)   | `#0E700E` / `#F1FAF1` |
| `statusWarningForeground` / `…Background` | 警示(黄)   | `#BC4B09` / `#FFF9F5` |
| `statusDangerForeground` / `…Background`  | 错误(红)   | `#B10E1C` / `#FDF3F4` |
| `statusSevereForeground` / `…Background`  | 严重(深橙) | `#DA3B01` / `#FDF6F3` |

#### 3.2.4 UI Refresh 2026 业务色

全应用校园仪表盘使用 `FluentAccentColors` 表达业务域强调色，页面只引用语义字段，不直接写十六进制颜色。当前业务域包括：`academic`、`schedule`、`information`、`mail`、`finance`、`sports`、`secondClassroom`、`quickLink`。

课程表使用 `FluentCoursePalette.colorFor(courseName)` 按课程名稳定映射颜色，避免同一课程在不同页面或刷新后变色。首页顶部、卡片材质和当前课程高亮使用 `FluentGradients`，页面不得自行拼装渐变。

#### 3.2.5 颜色使用规则

- 文本/图标用 `*Foreground*`,表面用 `*Background*`,边框用 `*Stroke*`,**不可混用**。
- 状态色仅表达状态语义,不得当作装饰色。
- 禁用态统一走 `*Disabled` 令牌,不要用透明度临时模拟。
- 不允许 `Colors.blue`、`Color(0xFF...)` 等裸值出现在组件代码中。

### 3.3 字体排版(Type Ramp)

Fluent 2 字阶(Web,Segoe UI;移动端字号一致、字体回退系统字体):

| 角色名              | 字重           | 字号 / 行高 (px) | 典型用途       |
| ------------------- | -------------- | ---------------- | -------------- |
| `caption2`          | Regular (400)  | 10 / 14          | 极小辅助文字   |
| `caption2Strong`    | Semibold (600) | 10 / 14          | 极小强调       |
| `caption1`          | Regular (400)  | 12 / 16          | 辅助说明、标签 |
| `caption1Strong`    | Semibold (600) | 12 / 16          | 辅助强调       |
| `caption1Stronger`  | Bold (700)     | 12 / 16          | 辅助最强强调   |
| `body1`             | Regular (400)  | 14 / 20          | **正文默认**   |
| `body1Strong`       | Semibold (600) | 14 / 20          | 正文强调       |
| `body1Stronger`     | Bold (700)     | 14 / 20          | 正文最强强调   |
| `subtitle2`         | Semibold (600) | 16 / 22          | 卡片标题       |
| `subtitle2Stronger` | Bold (700)     | 16 / 22          | 卡片标题强调   |
| `subtitle1`         | Semibold (600) | 20 / 26          | 区块标题       |
| `title3`            | Semibold (600) | 24 / 32          | 页面小标题     |
| `title2`            | Semibold (600) | 28 / 36          | 页面标题       |
| `title1`            | Semibold (600) | 32 / 40          | 大标题         |
| `largeTitle`        | Semibold (600) | 40 / 52          | 着陆页标题     |
| `display`           | Semibold (600) | 68 / 92          | 营销大字       |

字重映射到 Flutter:`Regular → FontWeight.w400`,`Medium → w500`,`Semibold → w600`,`Bold → w700`。

**规则**:

- 文本样式只能取自字阶令牌;禁止在 `TextStyle` 里直接写 `fontSize`。
- 需要改颜色时,从字阶样式 `copyWith(color: ...)`,而非新建样式。
- 整体放大/缩小走"整体提升字阶",不要为单个组件破例。
- 不用全大写来吸引注意(可读性差)。

### 3.4 间距(Spacing Ramp)

基准单位 **4px** 的 4x 体系;`2 / 6 / 10` 用于补偿图标内边距、对齐 4px 网格。

| 令牌            | 值 (px) | 令牌          | 值 (px) |
| --------------- | ------- | ------------- | ------- |
| `spacingNone`   | 0       | `spacingM`    | 12      |
| `spacingXXS`    | 2       | `spacingL`    | 16      |
| `spacingXS`     | 4       | `spacingXL`   | 20      |
| `spacingSNudge` | 6       | `spacingXXL`  | 24      |
| `spacingS`      | 8       | `spacingXXXL` | 32      |
| `spacingMNudge` | 10      |               |         |

水平与垂直共用同一比例阶梯。组件内部用较小间距强化关联,区块之间用较大间距区隔。

### 3.5 圆角(Corner Radius)

| 令牌             | 值 (px) | 用途                 |
| ---------------- | ------- | -------------------- |
| `radiusNone`     | 0       | 无圆角               |
| `radiusSmall`    | 2       | 小控件、标签         |
| `radiusMedium`   | 4       | **按钮、输入框默认** |
| `radiusLarge`    | 6       | 卡片                 |
| `radiusXLarge`   | 8       | 弹层、对话框、面板   |
| `radiusCircular` | 9999    | 头像、胶囊、圆形按钮 |

### 3.6 描边(Stroke Width)

| 令牌                  | 值 (px) | 用途             |
| --------------------- | ------- | ---------------- |
| `strokeWidthThin`     | 1       | 默认边框、分割线 |
| `strokeWidthThick`    | 2       | 焦点环、选中态   |
| `strokeWidthThicker`  | 3       | 强调态           |
| `strokeWidthThickest` | 4       | 特殊强调         |

### 3.7 高度与阴影(Elevation)

Fluent 2 提供一组阴影 ramp,数值越大层级越高。每个阴影由环境光层 + 方向光层叠加,**统一封装为令牌**。

| 令牌       | 典型用途           |
| ---------- | ------------------ |
| `shadow2`  | 轻浮起(悬停态卡片) |
| `shadow4`  | 卡片默认           |
| `shadow8`  | 下拉、菜单         |
| `shadow16` | 弹出层、Flyout     |
| `shadow28` | 对话框             |
| `shadow64` | 全屏覆盖层         |

> 另有品牌阴影(brand shadow)用于品牌色表面,落地后期再引入。当前阶段所有阴影只允许引用上述令牌,**禁止手写 `BoxShadow`**。

### 3.8 动效(Motion)

**时长令牌:**

| 令牌                | 值 (ms) | 用途         |
| ------------------- | ------- | ------------ |
| `durationUltraFast` | 50      | 极小状态反馈 |
| `durationFaster`    | 100     | 悬停、按下   |
| `durationFast`      | 150     | 小元素进出   |
| `durationNormal`    | 200     | **默认转场** |
| `durationSlow`      | 300     | 面板、抽屉   |
| `durationSlower`    | 400     | 大面积转场   |
| `durationUltraSlow` | 500     | 全屏转场     |
| `durationSkeleton`  | 1200    | 骨架屏 shimmer |

**缓动曲线令牌(对应 Flutter `Cubic`):**

| 令牌                 | cubic-bezier       | 用途              |
| -------------------- | ------------------ | ----------------- |
| `curveEasyEase`      | (0.33, 0, 0.67, 1) | **默认**,进出对称 |
| `curveDecelerateMid` | (0.1, 0.9, 0.2, 1) | 元素进入          |
| `curveAccelerateMid` | (0.7, 0, 1, 0.5)   | 元素退出          |
| `curveLinear`        | (0, 0, 1, 1)       | 进度、加载        |

**规则**:转场默认 `durationNormal + curveEasyEase`;进入用 decelerate,退出用 accelerate;尊重系统"减弱动态效果"(见 [§7](#7-无障碍))。

### 3.9 应用级度量(AppMetrics)

`AppMetrics` 统一页面内容宽度、首页磁贴高度、业务卡片高度、快速跳转磁贴尺寸和课表网格尺寸。页面内容封顶默认走 `FluentContentWidth`，首页业务磁贴默认走 `FluentDashboardTile`，课程表节次列宽和单元格高度从 `AppMetrics` 读取。

---

## 4. Flutter 架构实现

### 4.1 目录结构

```
lib/
└── design/
    ├── fluent/
    │   ├── tokens/
    │   │   ├── fluent_color_tokens.dart     # 中性/品牌/状态色,light & dark
    │   │   ├── fluent_typography.dart       # Type ramp → TextStyle
    │   │   ├── fluent_spacing.dart          # 间距阶梯
    │   │   ├── fluent_radii.dart            # 圆角
    │   │   ├── fluent_stroke.dart           # 描边宽度
    │   │   ├── fluent_elevation.dart        # 阴影
    │   │   └── fluent_motion.dart           # 时长 & 曲线
    │   ├── fluent_theme.dart                # 构建 FluentThemeData + 注入扩展
    │   └── fluent_context_ext.dart          # BuildContext 便捷访问扩展
    └── components/
        ├── fluent_button.dart
        ├── fluent_text_field.dart
        ├── fluent_card.dart
        ├── fluent_dashboard_tile.dart
        ├── fluent_bottom_drawer.dart
        ├── fluent_skeleton.dart
        ├── fluent_animated_number.dart
        ├── fluent_content_width.dart
        ├── fluent_material_surface.dart
        ├── fluent_nav_badge.dart
        └── ...
```

### 4.2 ThemeExtension 方案

每一类令牌实现为一个 `ThemeExtension`,以便参与主题切换与平滑插值。以颜色令牌为例:

```dart
// fluent_color_tokens.dart
import 'package:flutter/material.dart';

@immutable
class FluentColors extends ThemeExtension<FluentColors> {
  const FluentColors({
    required this.neutralBackground1,
    required this.neutralForeground1,
    required this.neutralForeground2,
    required this.neutralStroke1,
    required this.brandBackground,
    required this.brandBackgroundHover,
    required this.brandBackgroundPressed,
    required this.brandForeground1,
    required this.statusDangerForeground,
    // …其余令牌
  });

  final Color neutralBackground1;
  final Color neutralForeground1;
  final Color neutralForeground2;
  final Color neutralStroke1;
  final Color brandBackground;
  final Color brandBackgroundHover;
  final Color brandBackgroundPressed;
  final Color brandForeground1;
  final Color statusDangerForeground;

  @override
  FluentColors copyWith({
    Color? neutralBackground1,
    Color? neutralForeground1,
    Color? brandBackground,
    // …
  }) {
    return FluentColors(
      neutralBackground1: neutralBackground1 ?? this.neutralBackground1,
      neutralForeground1: neutralForeground1 ?? this.neutralForeground1,
      neutralForeground2: neutralForeground2,
      neutralStroke1: neutralStroke1,
      brandBackground: brandBackground ?? this.brandBackground,
      brandBackgroundHover: brandBackgroundHover,
      brandBackgroundPressed: brandBackgroundPressed,
      brandForeground1: brandForeground1,
      statusDangerForeground: statusDangerForeground,
    );
  }

  @override
  FluentColors lerp(ThemeExtension<FluentColors>? other, double t) {
    if (other is! FluentColors) return this;
    return FluentColors(
      neutralBackground1:
          Color.lerp(neutralBackground1, other.neutralBackground1, t)!,
      neutralForeground1:
          Color.lerp(neutralForeground1, other.neutralForeground1, t)!,
      neutralForeground2:
          Color.lerp(neutralForeground2, other.neutralForeground2, t)!,
      neutralStroke1: Color.lerp(neutralStroke1, other.neutralStroke1, t)!,
      brandBackground: Color.lerp(brandBackground, other.brandBackground, t)!,
      brandBackgroundHover:
          Color.lerp(brandBackgroundHover, other.brandBackgroundHover, t)!,
      brandBackgroundPressed:
          Color.lerp(brandBackgroundPressed, other.brandBackgroundPressed, t)!,
      brandForeground1:
          Color.lerp(brandForeground1, other.brandForeground1, t)!,
      statusDangerForeground:
          Color.lerp(statusDangerForeground, other.statusDangerForeground, t)!,
    );
  }

  // —— 主题预设:数值固化在此,UI 层不可见 Global Token ——
  static const light = FluentColors(
    neutralBackground1: Color(0xFFFFFFFF),
    neutralForeground1: Color(0xFF242424),
    neutralForeground2: Color(0xFF424242),
    neutralStroke1: Color(0xFFD1D1D1),
    brandBackground: Color(0xFF0F6CBD),
    brandBackgroundHover: Color(0xFF115EA3),
    brandBackgroundPressed: Color(0xFF0F548C),
    brandForeground1: Color(0xFF0F6CBD),
    statusDangerForeground: Color(0xFFB10E1C),
  );

  static const dark = FluentColors(
    neutralBackground1: Color(0xFF292929),
    neutralForeground1: Color(0xFFFFFFFF),
    neutralForeground2: Color(0xFFD6D6D6),
    neutralStroke1: Color(0xFF666666),
    brandBackground: Color(0xFF115EA3),
    brandBackgroundHover: Color(0xFF0F6CBD),
    brandBackgroundPressed: Color(0xFF2886DE),
    brandForeground1: Color(0xFF479EF5),
    statusDangerForeground: Color(0xFFDC626D),
  );
}
```

间距、圆角等"与主题无关"的令牌也用 `ThemeExtension`,但 light/dark 用同一份常量实例:

```dart
// fluent_spacing.dart
@immutable
class FluentSpacing extends ThemeExtension<FluentSpacing> {
  const FluentSpacing();

  double get none => 0;
  double get xxs => 2;
  double get xs => 4;
  double get sNudge => 6;
  double get s => 8;
  double get mNudge => 10;
  double get m => 12;
  double get l => 16;
  double get xl => 20;
  double get xxl => 24;
  double get xxxl => 32;

  @override
  FluentSpacing copyWith() => const FluentSpacing();

  @override
  FluentSpacing lerp(ThemeExtension<FluentSpacing>? other, double t) => this;
}
```

字阶令牌产出 `TextStyle`(`height` = 行高 ÷ 字号):

```dart
// fluent_typography.dart
@immutable
class FluentTypography extends ThemeExtension<FluentTypography> {
  const FluentTypography({this.fontFamily});

  final String? fontFamily;

  TextStyle _style(double size, double lineHeight, FontWeight weight) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: weight,
      );

  TextStyle get caption1 => _style(12, 16, FontWeight.w400);
  TextStyle get caption1Strong => _style(12, 16, FontWeight.w600);
  TextStyle get body1 => _style(14, 20, FontWeight.w400);
  TextStyle get body1Strong => _style(14, 20, FontWeight.w600);
  TextStyle get subtitle2 => _style(16, 22, FontWeight.w600);
  TextStyle get subtitle1 => _style(20, 26, FontWeight.w600);
  TextStyle get title3 => _style(24, 32, FontWeight.w600);
  TextStyle get title2 => _style(28, 36, FontWeight.w600);
  TextStyle get title1 => _style(32, 40, FontWeight.w600);
  TextStyle get largeTitle => _style(40, 52, FontWeight.w600);
  // …其余角色同理

  @override
  FluentTypography copyWith({String? fontFamily}) =>
      FluentTypography(fontFamily: fontFamily ?? this.fontFamily);

  @override
  FluentTypography lerp(ThemeExtension<FluentTypography>? other, double t) =>
      this;
}
```

### 4.3 主题构建

```dart
// fluent_theme.dart
FluentThemeData buildFluentTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colors = isDark ? FluentColors.dark : FluentColors.light;

  return FluentThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: colors.neutralBackground1,
    fontFamily: _defaultFluentFontFamily, // Segoe UI,缺失回退系统字体
    extensions: <ThemeExtension<dynamic>>[
      colors,
      const FluentSpacing(),
      const FluentRadii(),
      const FluentStroke(),
      const FluentElevation(),
      const FluentMotion(),
      FluentTypography(fontFamily: _defaultFluentFontFamily),
    ],
  );
}

// 平台相关字体回退
const _defaultFluentFontFamily = 'Segoe UI';
```

```dart
// main.dart
FluentApp(
  theme: buildFluentTheme(Brightness.light),
  darkTheme: buildFluentTheme(Brightness.dark),
  themeMode: ThemeMode.system,
  // …
);
```

### 4.4 令牌访问

提供 `BuildContext` 扩展,让组件内引用令牌简洁且强类型:

```dart
// fluent_context_ext.dart
extension FluentThemeX on BuildContext {
  FluentColors get fluentColors => FluentTheme.of(this).extension<FluentColors>()!;
  FluentTypography get fluentType =>
      FluentTheme.of(this).extension<FluentTypography>()!;
  FluentSpacing get fluentSpacing =>
      FluentTheme.of(this).extension<FluentSpacing>()!;
  FluentRadii get fluentRadii => FluentTheme.of(this).extension<FluentRadii>()!;
  FluentElevation get fluentElevation =>
      FluentTheme.of(this).extension<FluentElevation>()!;
  FluentMotion get fluentMotion => FluentTheme.of(this).extension<FluentMotion>()!;
}
```

使用示例:

```dart
Container(
  padding: EdgeInsets.all(context.fluentSpacing.m),     // 12
  decoration: BoxDecoration(
    color: context.fluentColors.neutralBackground1,
    borderRadius: BorderRadius.circular(context.fluentRadii.large), // 6
  ),
  child: Text('标题', style: context.fluentType.subtitle1),
);
```

---

## 5. 明暗主题

- 中性色与品牌色提供 `light` / `dark` 两套预设(见 [§4.2](#42-themeextension-方案));间距、圆角、动效等与主题无关的令牌共用一份。
- 切换主题靠替换整个 `ThemeExtension` 实例,`lerp` 保证过渡平滑。
- 颜色对比度在两种主题下都必须满足 [§7](#7-无障碍) 的要求,**不允许只为一种主题达标**。
- 不要用 `Theme.of(context).brightness` 在组件里做 `if/else` 选色;颜色差异应只存在于令牌预设中。

```dart
// ✅ 正确:语义令牌自动随主题切换
color: context.fluentColors.neutralForeground1,

// ❌ 错误:在组件里手动判明暗
color: isDark ? Colors.white : Colors.black,
```

---

## 6. 组件规范

组件统一封装在 `design/components/`,对外只暴露语义化参数,内部全部走令牌。

### 6.1 按钮(FluentButton)

外观(`appearance`):

| 外观              | 填充                 | 文本/图标            | 边框                 | 适用                |
| ----------------- | -------------------- | -------------------- | -------------------- | ------------------- |
| `primary`         | `brandBackground`    | 白色前景             | 无                   | 主操作,一屏至多一个 |
| `secondary`(默认) | `neutralBackground1` | `neutralForeground1` | `neutralStroke1` 1px | 常规操作            |
| `outline`         | 透明                 | `neutralForeground1` | `neutralStroke1` 1px | 次要操作            |
| `subtle`          | 透明                 | `neutralForeground2` | 无                   | 工具栏、低强调      |
| `transparent`     | 透明                 | `brandForeground1`   | 无                   | 类链接操作          |

尺寸(`size`):

| 尺寸           | 高度 | 水平内边距      | 字阶          |
| -------------- | ---- | --------------- | ------------- |
| `small`        | 24   | `spacingS` (8)  | `caption1`    |
| `medium`(默认) | 32   | `spacingM` (12) | `body1`       |
| `large`        | 40   | `spacingL` (16) | `body1Strong` |

通用规则:圆角 `radiusMedium` (4);交互态走 `*Hover` / `*Pressed` 颜色令牌;禁用态用 `*Disabled` 令牌;焦点环用 `strokeWidthThick` (2) + `brandStroke1`;过渡 `durationFaster` (100ms)。

### 6.2 输入框(FluentTextField)

- 高度 32(中);圆角 `radiusMedium`;内边距 `spacingM`。
- 描边:默认 `neutralStroke1` 1px;聚焦时底部强调线 `brandStroke1` 2px。
- 文本 `body1`,占位 `body1` + `neutralForeground3`;标签 `caption1Strong`。
- 错误态:描边与辅助文字用 `statusDangerForeground`,辅助文字为 `caption1`。

### 6.3 卡片(FluentCard)

- 表面 `neutralBackground1`;圆角 `radiusLarge` (6);内边距 `spacingL` (16)。
- 默认阴影 `shadow4`,可悬停卡片 hover 时升至 `shadow8`(过渡 `durationFast`)。
- 卡片标题 `subtitle2`,正文 `body1`。

### 6.4 通用组件清单(渐进实现)

`FluentAppBar / NavBar`、`FluentDialog`(`radiusXLarge` + `shadow28`)、`FluentMenu`(`shadow8`)、`FluentAvatar`(`radiusCircular`)、`FluentBadge`、`FluentSwitch`、`FluentCheckbox`、`FluentTabs`、`FluentProgress`。每个组件落地时都需在本节补一张令牌映射表。

---

## 7. 无障碍

- **对比度**:正文文本与背景对比度 ≥ **4.5:1**;大文本(≥ 18.66px 粗体或 24px 常规)≥ **3:1**。图标与可交互边界 ≥ 3:1。
- **触达区域**:可点击元素最小命中区域 48×48 dp(必要时用透明 padding 扩展,不放大视觉尺寸)。
- **焦点可见**:键盘/手柄聚焦必须有可见焦点环(`strokeWidthThick` + `brandStroke1`)。
- **语义标注**:为图标按钮、自定义控件提供 `Semantics` 标签;状态变化通过 `liveRegion` 播报。
- **不以颜色为唯一信息**:错误/成功等状态需同时辅以图标或文字。
- **动态字体**:不写死字号,尊重系统 `textScaler`;布局需在放大字号下不溢出。
- **减弱动态效果**:检测 `MediaQuery.disableAnimations`,为 true 时缩短或跳过非必要动效。

---

## 8. 工程约定

- **裸值零容忍**:`Color(0xFF...)`、`Colors.*`、裸 `EdgeInsets.all(16)`、裸 `fontSize` 一律不进主分支。可在 CI 加 lint/grep 规则拦截。
- **唯一入口**:UI 只通过 `context.fluent*` 访问令牌;`tokens/` 目录之外不得出现 Global 令牌。
- **组件优先**:页面优先使用 `lib/design/fluent_ui.dart` 导出的外部 Fluent 控件、语义 `FluentIcons` 与 `design/components/` 业务组合组件,不直接使用 Material 命名的可见控件或 Material 图标。
- **命名一致**:Dart 端令牌命名与 Fluent 2 官方语义保持一致(`neutralForeground1`、`brandBackgroundHover` 等),便于与设计稿对照。
- **令牌新增流程**:新令牌先加入 `tokens/`,再在组件中引用;禁止"先在组件里写值,以后再抽"。
- **快照测试**:核心组件在 light/dark 两种主题下做 golden test,防止令牌回归。

---

## 9. 与第三方包的关系

- 当前实现采用外部 `fluent_ui` 作为 Fluent 控件与 `FluentApp` / `NavigationView` / `ScaffoldPage` / `ContentDialog` / `InfoBar` / `TextBox` 等可见 UI 的主要来源。
- 当前实现采用外部 `fluentui_system_icons` 作为图标唯一来源;页面层通过项目语义 `FluentIcons` facade 引用图标,避免直接依赖 Material `Icons.*` 或外部包的原始图标名。
- 项目仍保留 `lib/design/fluent/` 兼容 token 与 `design/components/` 业务组合组件,用于跨页面语义、历史 API 兼容和统一间距/圆角/动效;这些组件内部应优先委托外部 Fluent 控件实现。

---

## 10. 维护与变更流程

1. **设计侧变更**:Fluent 2 Figma UI Kit 更新令牌 → 设计负责人在本文档登记差异。
2. **令牌同步**:开发侧更新 `tokens/` 中对应常量,运行 golden test。
3. **评审**:令牌或本文档的改动需经设计 + 前端双方评审合并。
4. **版本记录**:每次令牌变更在下表追加一行。
5. **核对官方真源**:颜色等数值定期与 `@fluentui/tokens` / 官方 Figma 核对。

### 变更记录

| 日期       | 版本  | 变更内容                         | 负责人 |
| ---------- | ----- | -------------------------------- | ------ |
| 2026-05-18 | 0.1.0 | 初始版本:令牌体系与 Flutter 架构 | Qintsg |
| 2026-05-19 | 0.2.0 | 落地实现:7 个 ThemeExtension 令牌固化于 `lib/design/fluent/`,ColorScheme/TextTheme 桥接全量传播,核心组件库(Button/Card/TextField/Surface/InfoBar/Dialog/SectionHeader),`lib/theme/` 保留历史主题入口并指向 Fluent 2 主题。**偏离记录**:§1.2 桌面建议 Segoe UI,本项目面向中文用户,主族固定为已内置覆盖 w300–w700 的 MiSans(Segoe UI 缺 CJK 字形必然回退),数值与字阶严格遵循 §3。 | Qintsg |

---

### 参考

- Fluent 2 Design System — 设计令牌 / 排版 / 布局 / 颜色令牌:`fluent2.microsoft.design`
- Fluent UI 令牌命名规范:`microsoft.github.io/fluentui-token-pipeline`
- 官方令牌包:`@fluentui/tokens`(npm)
