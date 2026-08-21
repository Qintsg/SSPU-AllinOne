# 基础层 · Foundations

设计系统的原子层——令牌、尺度、规则。所有组件与模式都从这里派生。

---

## 目录

| 规范 | 摘要 |
|---|---|
| [颜色 · Color](./color.md) | 中性色 / 品牌青雾 / 墨蓝结构 / 八业务域分类色 / 状态色；亮暗双值 + OKLch 生成规则 |
| [字体 · Typography](./typography.md) | MiSans w300–700 / 7 级字阶 / 行高 / 字距 / 层级用法 |
| [间距 · Spacing](./spacing.md) | 4px 基准阶 / 组件内外间距 / 密度三档 |
| [阴影 · Elevation](./elevation.md) | e0–e3 四级 / 对应场景 / 暗色适配 |
| [动效 · Motion](./motion.md) | Ease-out 主曲线 / 三档时长 / 禁用场景 |
| [令牌 · Tokens](./tokens.md) | 完整 token → Flutter ThemeExtension 映射表 + 机器可读 JSON |

---

## 原则重申

1. **清透** — 低饱和中性 + 单支行动色（青雾）+ 域色分类；阴影克制、留白充裕。
2. **本地优先** — 数据全本地、不上云；UI 里显化这条信任（本地盾形、引用卡）。
3. **可生长** — 业务域不止八个；分类色与组件体系都留扩展位。
4. **五端一致** — Android、iOS、Windows、macOS、Linux 使用同一套语义 token 与组件契约；导航形态、密度、鼠标/触控/键盘反馈按平台能力适配。Flutter Web 不在本轮验收范围。

---

## 如何使用

- **实现新组件**：先查 [tokens.md](./tokens.md) 找到对应令牌，再到 `components/` 读组件规格，拿 Flutter 骨架落地。
- **定制主题**：先改 [`resources/tokens.json`](../resources/tokens.json) 的 `color.brand`，再同步文档与镜像并运行契约校验。
- **校验对比度**：颜色规范里已标明所有前景/背景配对的 WCAG 等级；若自定义颜色需重新跑 [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)。

---

**变更记录** → 见 [CHANGELOG.md](../CHANGELOG.md)
