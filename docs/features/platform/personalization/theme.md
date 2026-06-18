# 主题与深色模式

> 子模块：[个性化](README.md)　·　状态：**部分实现**（token 体系已实现，切换设计中）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.personalization.theme` |
| 状态 | 部分实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #168 |
| 主要代码 | `lib/theme/`；`lib/design/fluent/fluent_theme.dart`、`tokens/` |

## 1. 需求

支持深色模式与主题切换（#168）：亮/暗/跟随系统，主题（行动色/强调色）可选；偏好持久化。

**验收要点**
- 亮色 / 暗色 / **跟随系统** 三态切换。
- 主题 token 双主题集中切换，零裸值（见 [`DESIGN.md`](../../../../DESIGN.md)）。
- 偏好本地持久化、即时生效。

## 2. 实现

- 设计系统 token（`design/fluent/tokens/`）已支持亮/暗双主题，映射 Flutter `ThemeExtension`。
- 主题模式（亮/暗/系统）与可选强调色在 [设置中心](../shell/settings.md)「主题」分区选择，偏好落 [本地存储](../system/storage-sync.md)。

## 3. 关联

- 依赖：设计系统 token（`DESIGN.md`）、[设置中心](../shell/settings.md)、[本地存储](../system/storage-sync.md)。
- 被依赖：全应用 UI。

## 4. 约束

- 颜色全部来自语义 token，代码零裸值；亮/暗集中切换。

## 5. 待办与演进

- [ ] 亮/暗/系统切换与主题选择 UI（#168）。
- [ ] 偏好持久化与即时生效。
