# Spec Kit 规格目录

本目录保存由 GitHub Spec Kit 驱动的功能规格、实现计划和任务清单。每个功能使用
`NNN-kebab-case/` 目录，并按以下顺序推进：

1. `$speckit-specify`：描述用户场景、需求和可验收结果，生成 `spec.md`。
2. `$speckit-clarify`（可选）：消除需求歧义。
3. `$speckit-plan`：记录 Flutter/Dart 技术方案，生成 `plan.md`。
4. `$speckit-tasks`：拆分可独立执行的任务，生成 `tasks.md`。
5. `$speckit-implement`：按任务实现并运行项目质量门禁。
6. `$speckit-converge`：对照规格、计划和任务清单收敛剩余工作。

规格文件必须与实现一起提交。GitHub Actions 中的 `Spec Kit` 工作流会持续检查
`.specify` 基础设施、Codex 技能和项目宪章是否完整。
