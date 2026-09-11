# Implementation Plan: 校园服务能力收敛

**Branch**: `feature/frontend-visual-refresh` | **Date**: 2026-09-09 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-campus-service-completion/spec.md`

## Summary

在现有清源 Flutter 应用中收敛多个已开展的校园服务能力：以仓库现有服务与页面为主线，复用成熟的邮件、文件选择、本地通知、时区和系统文件打开依赖；统一模块偏好、学术日程、邮件附件、消费趋势与微信刷新模型；补齐 macOS 发布门禁、通知权限可见性、普通消息独立开关、教务详情失败恢复、自动化测试、真实平台验收说明及全量功能文档。计划不引入新的校园系统写操作，也不把真实设备验证等同于单元测试通过。

## Technical Context

**Language/Version**: Dart 3.12.0；Flutter SDK >= 3.44.0；macOS 发布脚本使用 GitHub Actions、PowerShell/Python 辅助校验

**Primary Dependencies**: 清源设计系统；`enough_mail`；`file_picker`；`flutter_local_notifications`；`timezone`；`open_filex`；`dio`；`flutter_secure_storage`；`path_provider`

**Storage**: 平台默认应用数据目录中的 `app_state.json` 与账号隔离缓存；敏感凭据使用系统安全存储

**Testing**: `flutter_test` 单元/Widget 测试、Dart 静态分析、格式门禁、设计系统校验、GitHub Actions 静态校验、Windows release 构建及目标平台真实验收

**Target Platform**: Android、iOS、Windows、macOS、Linux；macOS 正式发布包含 universal DMG

**Project Type**: 单体跨平台 Flutter 应用，包含平台 Runner 与发布工作流

**Performance Goals**: 本地搜索在 100 封邮件范围内 1 秒内完成；首页设置切换不触发被禁模块请求；刷新任务去重且不会并发重复执行

**Constraints**: 校园服务只读；凭据不进入普通状态文件或日志；产品 UI 只使用清源 facade 与 token；平台能力差异必须显式呈现；发布材料缺失时失败关闭

**Scale/Scope**: 10 个用户故事、24 条功能要求，约 30 个核心模型/服务/页面与其测试、平台配置、发布工作流和功能文档；第二轮收敛补充普通消息通知、通知权限查询和教务错误状态恢复契约

## Constitution Check

*GATE: Phase 0 前与 Phase 1 后均通过。*

- **I 用户价值优先**：PASS。规格包含 10 个可独立验证用户故事、明确优先级、验收场景与量化成功标准。
- **II Flutter 设计系统一致性**：PASS。所有新增或调整页面继续经 `design/qingyuan/qingyuan_ui.dart` 使用清源组件与令牌，不引入 Material/Cupertino 产品控件。
- **III 测试先行与质量门禁**：PASS。每个故事映射到现有或待补测试；最终按 format、analyze、test 顺序运行，并补发布/设计/治理校验。
- **IV 本地数据与最小权限**：PASS。普通状态与缓存落平台应用目录，凭据留在系统安全存储；教务、校园卡与微信能力保持只读。
- **V 可审查的增量交付**：PASS。本目录建立 spec → plan → tasks 链路；不在本计划中执行提交、推送或 PR。

## Project Structure

### Documentation (this feature)

```text
specs/001-campus-service-completion/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── behavior-contracts.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── models/                    # 教务、邮箱、校园卡、消息与趋势数据
├── pages/                     # 首页、教务、课表、邮箱、消费统计与设置 UI
├── services/                  # 网关、解析、偏好、刷新、提醒、导出与通知
├── design/qingyuan/           # 清源 facade、组件、图标与 token
└── widgets/                   # 设置区块与共享状态组件

assets/config/                 # 快捷入口与公众号配置
android/ ios/ macos/ windows/ linux/  # 平台 Runner 与能力声明
.github/workflows/release.yml  # macOS 签名、公证、装订与产物校验
scripts/                       # 发布、治理、设计与规格校验
docs/features/                 # 功能矩阵、路线图与模块文档
test/                          # 单元、Widget、平台配置与发布脚本测试
```

**Structure Decision**: 保持现有单体 Flutter 结构；领域模型放 `lib/models/`，平台无关逻辑放 `lib/services/`，清源页面放 `lib/pages/`，平台能力只在 Runner、插件配置和 release workflow 中实现。不会为单项功能另建子应用或重复邮件/通知协议栈。

## Phase 0: Research Decisions

研究结论见 [research.md](research.md)。核心决策是继续复用现有成熟依赖与网关边界；邮件协议、附件选择、本地通知、时区和系统文件关联均不自行实现。

## Phase 1: Design & Contracts

- 数据结构、验证规则和状态转换见 [data-model.md](data-model.md)。
- 页面、服务、平台和发布行为契约见 [contracts/behavior-contracts.md](contracts/behavior-contracts.md)。
- 可复现验收与质量门禁见 [quickstart.md](quickstart.md)。

## Post-Design Constitution Check

- 清源 UI、测试映射、本地隐私、只读边界和规格追踪均保持 PASS。
- 真实平台验收被保留为独立证据，不以 Windows 本地构建替代 macOS/移动端验证。
- 无需宪章例外，Complexity Tracking 留空。

## Complexity Tracking

无宪章违规或需要额外合理化的复杂度。
