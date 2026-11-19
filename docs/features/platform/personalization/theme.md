# 主题与深色模式

> 子模块：[个性化](README.md)　·　状态：**已实现**

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.personalization.theme` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #168 |
| 主要代码 | `lib/design/qingyuan/app/yh_app.dart`、`lib/design/qingyuan/components/yh_miuix.dart`、`lib/pages/settings_appearance_page.dart` |

## 1. 需求

支持深色模式与主题切换（#168）：亮/暗/跟随系统，主题（行动色/强调色）可选；偏好持久化。

**验收要点**
- 亮色 / 暗色 / **跟随系统** 三态切换。
- Monet 动态配色独立开关。支持系统取色的 Android 使用壁纸色，其他平台从品牌色生成配色。
- 偏好本地持久化、即时生效。

## 2. 实现

- 应用根节点使用 Miuix 主题控制器，将颜色映射到清源页面的背景、表面、交互和导航等语义角色。
- 在[设置中心](../shell/settings.md)的“外观”页调整明暗模式或启用 Monet。两项偏好独立保存到[本地设置](../system/storage-sync.md)，切换时保留当前页面。

## 3. 关联

- 依赖：清源设计系统 token（`DESIGN.md`）、[设置中心](../shell/settings.md)、[本地存储](../system/storage-sync.md)。
- 被依赖：全应用 UI。

## 4. 约束

- 颜色全部来自语义 token，代码零裸值；亮/暗集中切换。

## 5. 待办与演进

- [x] 亮/暗/系统切换与主题选择 UI（#168）。
- [x] 偏好持久化与即时生效。
