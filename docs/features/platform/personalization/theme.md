# 主题与深色模式

> 子模块：[个性化](README.md)　·　状态：**已实现**（清源 token 体系 + 亮/暗/系统切换 + 偏好持久化）

| 项 | 内容 |
| --- | --- |
| 功能 ID | `platform.personalization.theme` |
| 状态 | 已实现 |
| 平台 | 全平台（Android · iOS · Windows · macOS · Linux） |
| 关联 Issue | #168 |
| 主要代码 | `lib/design/qingyuan/theme/yh_theme.dart`；`lib/pages/settings_appearance_page.dart` |

## 1. 需求

支持深色模式与主题切换（#168）：亮/暗/跟随系统，主题（行动色/强调色）可选；偏好持久化。

**验收要点**
- 亮色 / 暗色 / **跟随系统** 三态切换。
- 主题 token 双主题集中切换，零裸值（见 [`DESIGN.md`](../../../../DESIGN.md)）。
- 偏好本地持久化、即时生效。

## 2. 实现

- 清源设计系统 token（`lib/design/qingyuan/theme/yh_theme.dart`）支持亮/暗双主题，映射 Flutter `ThemeExtension`。
- 主题模式（亮/暗/系统）在 [设置中心](../shell/settings.md)「外观」分区（`SettingsAppearancePage`）选择，偏好通过 `StorageService.themeMode` 落 [本地存储](../system/storage-sync.md) 并即时生效。

## 3. 关联

- 依赖：清源设计系统 token（`DESIGN.md`）、[设置中心](../shell/settings.md)、[本地存储](../system/storage-sync.md)。
- 被依赖：全应用 UI。

## 4. 约束

- 颜色全部来自语义 token，代码零裸值；亮/暗集中切换。

## 5. 待办与演进

- [x] 亮/暗/系统切换与主题选择 UI（#168）。
- [x] 偏好持久化与即时生效。
