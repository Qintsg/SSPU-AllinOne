# Release Pull Request

## 发布信息

- 公开版本（不含 `+build`）：
- `pubspec.yaml` 完整版本（含 `+build`）：
- Git Tag：
- 发布通道：stable / alpha / beta / rc / lts / hotfix
- 发布类型：普通 Release / Pre-release / 重新发布

## 关联事项

<!-- 需要关闭 Issue 时保留 Closes / Fixes / Resolves；仅引用请写 Refs #123。 -->
Closes #

## 分支确认

- [ ] 已确认分支流向和 `release` label 使用正确
- [ ] 已确认版本号只修改 `pubspec.yaml` 与 `docs/CHANGELOG.md`
- [ ] 已确认安装包文件名和 Release 标题不含 `+build`

## 验证记录

- [ ] `flutter analyze` + `flutter test`
- [ ] 四平台构建验证
- [ ] 手动验证关键路径

## 检查清单

- [ ] 未提交签名密钥、token 等敏感信息
- [ ] `release` label 仅在应触发 Release 的 PR 上添加

---

## 发布说明

<!--
Release workflow 会直接从下列章节生成 release-notes.md 与 GitHub Release 正文。
若无对应内容，请写"无"。不允许保留"待补充"等占位文本。
-->

## 亮点

## 新增

## 修复

## 优化

## 破坏性变更

- 无

## 已知问题

- 无
