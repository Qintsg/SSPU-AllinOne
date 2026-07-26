# 设计令牌 Tokens

清源的所有视觉值（颜色 / 字阶 / 间距 / 阴影 / 圆角 / 动效 / 断点 / 控件尺寸）都通过 token 声明。`docs/design/resources/tokens.json` 是唯一机器真源，代码层通过 `YhTheme` 读取其生成或校验后的 Flutter 映射。

业务域图标浅底使用 `opacity.domainTint = 0.14` 与当前 `surface` 混合；页面和组件不得自行写透明度常量。

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
│  ├─ hero / display / h1 / h2 / h3 / body / reading / small / caption
│  └─ fontFamilyDisplay / fontFamilyBody / fontFamilyMono
├─ spacing                # 间距（见 spacing.md）
│  └─ xs / s / m / l / xl / xl2
├─ opacity                # 混色透明度
│  └─ domainTint
├─ elevation              # 阴影（见 elevation.md）
│  └─ e0 / e1 / e2 / e3
├─ radius                 # 圆角
│  └─ s(10) / m(16) / l(24) / full(999)
├─ duration / curves      # 动效（见 motion.md）
├─ breakpoint             # compact / medium / expanded / large
├─ control                # compact / regular / touch / minimumTarget
├─ focus                  # ringWidth / ringGap
└─ interaction            # pressedScale
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

// 迁移期注入现有 FluentThemeData.extensions；未来宿主可替换，组件接口不变。

// 组件内读取
final theme = context.yhTheme;
Container(
  color: theme.color.neutral.surface,
  padding: EdgeInsets.all(theme.spacing.l),
);
```

## JSON 导出（供设计工具 / Web 复用）

`docs/design/resources/tokens.json` 维护机器可读版本。文档不再复制一份可被误认为权威的完整 JSON；具体值直接查看该文件。

CI 必须验证 JSON、样例 CSS 与 Flutter 映射一致；任何镜像值漂移都视为构建失败。

## 原则

- 所有会跨组件复用的视觉值禁止硬编码——颜色必须 `theme.color.*`，间距必须 `theme.spacing.*`。
- Token 分组按"用途"，不按"数值"（不搞 `blue500 / spacing16` 这种无语义命名）。
- 新增 token 前先问“这个值是否表达稳定语义且会在 3+ 处复用”；单次布局计算可以留在实现内部，不进入公共接口。
