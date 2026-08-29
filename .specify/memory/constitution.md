<!--
Sync Impact Report
Version change: scaffold → 1.0.0
Modified principles: replaced all generic Spec Kit placeholders with SSPU-AllinOne rules
Added sections: Flutter technology constraints; Git Flow and review quality gates
Removed sections: none
Deferred items: none
-->

# SSPU-AllinOne Constitution

## Core Principles

### I. 用户价值优先

每项功能 MUST 从可独立验证的用户场景开始，并在规格中写明优先级、验收场景和可衡量的
成功标准。实现范围 MUST 以规格为边界；未解决的歧义 MUST 在计划前通过澄清记录解决。

### II. Flutter 设计系统一致性

面向用户的 Flutter UI MUST 遵循仓库现有 Fluent UI 与清源设计系统，复用项目 facade、组件
和设计令牌。新组件 MUST 放在对应的 `design/` 目录，并通过现有设计契约校验；不得在产品
界面直接引入 Material/Cupertino 控件或硬编码颜色、间距和字号。

### III. 测试先行与质量门禁

每个用户故事 MUST 具有独立测试路径；实现 MUST 至少包含覆盖关键行为的 Dart/Flutter 测试。
提交前 MUST 按 `dart format`、`flutter analyze --no-fatal-infos`、`flutter test` 顺序执行适用
检查。规格、计划和任务清单中的验收标准 MUST 能映射到测试或可复现的验证步骤。

### IV. 本地数据与最小权限

用户数据 MUST 保存在各平台默认应用数据目录；凭据 MUST 使用系统安全存储。应用只提供
只读查询，不得新增选课、支付、充值或其他写入校园系统的操作。GitHub Actions MUST 遵循
最小权限原则，并固定第三方 Action 到可审计的提交 SHA。

### V. 可审查的增量交付

每项变更 MUST 通过 `spec.md` → `plan.md` → `tasks.md` 建立可追踪链路，并以小步、可回滚的
提交交付。常规 PR MUST 以 `develop` 为目标分支，标题 MUST 符合仓库约定并包含中文摘要；
影响架构或治理的取舍 MUST 记录在 Lore 决策元数据中。

## Technology Constraints

- 项目使用 Flutter `>= 3.44.0` 与 Dart `3.12.0`；依赖变更 MUST 同步更新锁文件并通过 CI。
- 本地状态 MUST 遵循 `README_agents.md` 中的平台路径和隐私约束，不得提交令牌、密钥或机器
  专属配置。
- 新增 API 文档 MUST 使用 OpenAPI 3.0，并通过 Redocly CLI 校验。

## Development Workflow

1. 使用 `$speckit-specify` 创建规格；必要时先使用 `$speckit-clarify`。
2. 使用 `$speckit-plan` 形成技术方案，使用 `$speckit-tasks` 生成可执行任务。
3. 在任务分支上实现并运行质量门禁；使用 `$speckit-converge` 对照规格收敛。
4. PR 必须包含验证证据，并通过现有 CI、治理和安全工作流后方可合并。

## Governance

本宪章优先于未明确覆盖同一问题的局部约定。修改宪章 MUST 在 PR 中说明影响范围、迁移
计划（如有）和版本变更原因，并同步更新受影响的模板、规格或工作流。版本遵循语义化版本：
删除或重新定义原则时递增 MAJOR；新增原则或重大扩展时递增 MINOR；措辞澄清和非语义修订时
递增 PATCH。所有 PR 的审查者 MUST 检查规格链路、隐私约束和质量门禁是否满足；若规则与
现有实现冲突，必须在合并前记录并解决例外。

**Version**: 1.0.0 | **Ratified**: 2026-08-30 | **Last Amended**: 2026-08-30
