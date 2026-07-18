# 设计令牌 Tokens

清源的所有视觉值（颜色 / 字阶 / 间距 / 阴影 / 圆角）都通过 **token** 声明，代码层通过 `YhTheme` 单一真源读取。

## Token 结构

```
YhTheme
├─ color                  # 颜色令牌（见 color.md）
│  ├─ neutral { bg, surface, fg, muted, border, bgElevated }
│  ├─ brand { base, strong, text, icon, bgSubtle, bgMuted }
│  ├─ structural { base, strong, ... }
│  ├─ accent { academic, schedule, news, ... }  # 8 业务域
│  └─ status { successBg, ... }
├─ typography             # 字体令牌（见 typography.md）
│  ├─ display / h1 / h2 / h3 / body / small / caption
│  └─ fontFamilyDisplay / fontFamilyBody / fontFamilyMono
├─ spacing                # 间距（见 spacing.md）
│  └─ xs / s / m / l / xl / xl2 / xl3
├─ elevation              # 阴影（见 elevation.md）
│  └─ e0 / e1 / e2 / e3 / e4
├─ radius                 # 圆角
│  └─ s(10) / m(16) / l(24) / full(999)
└─ duration / curves      # 动效（见 motion.md）
```

## Flutter 实现（骨架）

```dart
class YhTheme extends ThemeExtension<YhTheme> {
  final YhColorTokens color;
  final YhTypographyTokens typography;
  // ... 其余 token 组

  const YhTheme({required this.color, required this.typography, ...});

  // copyWith / lerp 实现略
}

// 亮暗两套实例
final yhLightTheme = YhTheme(
  color: YhColorTokens.light(),
  typography: YhTypographyTokens(),
  // ...
);
final yhDarkTheme = YhTheme(
  color: YhColorTokens.dark(),
  typography: YhTypographyTokens(),
  // ...
);

// 全局注入
MaterialApp(
  theme: ThemeData(extensions: [yhLightTheme]),
  darkTheme: ThemeData(extensions: [yhDarkTheme]),
);

// 组件内读取
final theme = Theme.of(context).extension<YhTheme>()!;
Container(
  color: theme.color.neutral.surface,
  padding: EdgeInsets.all(theme.spacing.l),
);
```

## JSON 导出（供设计工具 / Web 复用）

`docs/design/resources/tokens.json` 维护机器可读版本：

```json
{
  "color": {
    "neutral": {
      "bg":      { "light": "#F7F6F5", "dark": "#14171A" },
      "surface": { "light": "#FFFFFF", "dark": "#1E2226" },
      "fg":      { "light": "#1C1B1A", "dark": "#E8E6E3" },
      "border":  { "light": "#D1CEC9", "dark": "#353A3F" }
    },
    "brand": {
      "base":   { "light": "#6FA3A4", "dark": "#7FB0B1" },
      "strong": { "light": "#478384", "dark": "#5C9A9B" },
      "tint":   { "light": "#E9F0F0", "dark": "#1E3233" },
      "ink":    { "light": "#356263", "dark": "#A8CFCF" }
    }
  },
  "spacing": { "xs": 4, "s": 8, "m": 16, "l": 24, "xl": 32 },
  "radius": { "s": 10, "m": 16, "l": 24, "full": 999 }
}
```

## 原则

- **所有组件禁止硬编码数值**——颜色必须 `theme.color.*`，间距必须 `theme.spacing.*`。
- Token 分组按"用途"，不按"数值"（不搞 `blue500 / spacing16` 这种无语义命名）。
- 新增 token 前先问"这个值会在 3+ 处复用吗"——单次用的值直接写，别污染 token 表。
