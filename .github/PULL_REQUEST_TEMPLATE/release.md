# Release Pull Request

## 背景与目标
<!-- 说明本次发布的背景、目标公开版本、发布原因 -->

## 关联事项
<!-- 关联当前仓库内的 Issue / 任务 -->
Closes #

## 发布信息
- 公开版本（不含 `+build`）：
- `pubspec.yaml` 完整版本（含 `+build`）：
- Git Tag：
- 发布通道：
    - [ ] stable：稳定版
    - [ ] alpha：早期预发布
    - [ ] beta：测试版
    - [ ] rc：候选发布版
    - [ ] lts：长期支持版
    - [ ] hotfix：热修复版

## 发布类型
- [ ] 普通 Release（stable / lts / hotfix）
- [ ] Pre-release（alpha / beta / rc）
- [ ] 重新发布（仅递增 `+build`）

## 分支与标签确认
- [ ] alpha / beta / rc：本 PR 为 `release/v... -> develop`，并已添加 `release` label
- [ ] stable / lts / hotfix 第一段：本 PR 为 `release/v... -> develop`，且没有添加 `release` label
- [ ] stable / lts / hotfix 第二段：本 PR 为 `develop -> main`，并已添加 `release` label
- [ ] 已确认版本号只修改了 `pubspec.yaml` 与 `docs/CHANGELOG.md`
- [ ] 已确认安装包文件名、Release 标题和 Release 描述不显式包含 `+build`

## 影响范围
- [ ] Flutter 前端（`lib/`）
- [ ] 平台工程（Android / iOS / macOS / Linux / Windows / Web）
- [ ] 依赖 / 工具链
- [ ] GitHub 工作流 / Release
- [ ] 安装包 / 构建产物
- [ ] 文档
- [ ] 其他：

## 风险与回滚
- 风险等级：
    - [ ] 低
    - [ ] 中
    - [ ] 高
- 主要风险：
- 回滚方案：

## 验证记录
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Android 构建验证
- [ ] Windows 构建验证
- [ ] macOS 构建验证
- [ ] Linux 构建验证
- [ ] Web 构建验证
- [ ] 手动验证（请补充关键路径）
- [ ] 未执行部分验证（请说明原因）

## 截图 / 录屏（如涉及 UI）
<!-- 若无，可写“无” -->

---

## 发布说明

<!--
Release workflow 会直接从下列章节生成 release-notes.md 与 GitHub Release 正文。

要求：
1. 带 `release` label 时，必须将下列章节替换为真实内容。
2. 不允许保留“请填写”“待补充”等模板占位文本。
3. 若无对应内容，请明确写“无”或“无已知问题”。
4. 若本 PR 不触发公开 Release，请不要添加 `release` label。
5. 不要在发布说明中显式写出 `+build`。
-->

## 亮点

-

## 新增

-

## 修复

-

## 优化

-

## 破坏性变更

- 无破坏性变更

## 安装 / 升级说明

- 新装用户：
- 升级用户：
- 是否需要清理旧配置：

## 已知问题

- 无已知问题
