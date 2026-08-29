# SSPU-AllinOne Agent 指南

完整的项目约定、Git Flow、质量门禁、隐私和设计系统规则见
[README_agents.md](README_agents.md)。本文件补充 GitHub Spec Kit 的项目级使用规则。

## GitHub Spec Kit 工作流

本项目使用 [GitHub Spec Kit](https://github.com/github/spec-kit) 推行规格驱动开发（SDD）。
规格资产位于 `.specify/` 和 `specs/`，Codex 技能位于 `.agents/skills/speckit-*/`。
新增需求应按以下顺序推进：

1. `$speckit-specify`：创建用户场景、需求和验收标准。
2. `$speckit-clarify`（可选）：在技术规划前消除歧义。
3. `$speckit-plan`：形成 Flutter/Dart 技术方案。
4. `$speckit-tasks`：拆分可执行任务并建立验收映射。
5. `$speckit-implement`：按任务实现并运行项目质量门禁。
6. `$speckit-converge`：对照规格、计划和任务清单收敛剩余工作。

### 需求与 Skill 匹配优先级

当用户提出需求时，agent MUST 优先判断是否存在匹配的 `speckit` skill，并在适用时先使用
它来维护规格驱动链路：

- 新功能、产品需求或用户场景：优先 `$speckit-specify`。
- 需求不完整或存在决策分歧：优先 `$speckit-clarify`。
- 架构、技术选型或实现方案：优先 `$speckit-plan`。
- 任务拆分、里程碑或执行清单：优先 `$speckit-tasks`。
- 已有规格和任务、要求开始编码：优先 `$speckit-implement`。
- 完成实现后的规格一致性检查：优先 `$speckit-converge` 或 `$speckit-analyze`。
- 需要质量核对清单：使用 `$speckit-checklist`。
- 需要把任务转成 GitHub Issue：使用 `$speckit-taskstoissues`。
- 修改项目原则或治理规则：仅使用 `$speckit-constitution`。

若需求明确属于仓库已有的工程 skill（例如分支、提交、PR、Issue 或 Lore），仍须遵循
对应工程 skill；涉及新功能时，应先完成 Spec Kit 规格阶段，再进入实现流程。不得为了
匹配 skill 而执行超出用户授权范围的实现、发布或外部写入操作。

## 校验要求

`.github/workflows/spec-kit.yml` 会在规格基础设施或规格资产变更时运行
`scripts/ci/validate_spec_kit.py`。提交前应确认宪章没有未替换占位符，并确保
`spec.md`、`plan.md`、`tasks.md` 与实现变更保持可追踪。
