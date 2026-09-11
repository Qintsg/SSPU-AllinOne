# Implementation Plan: 校园工作台响应式收敛

**Branch**: `bugfix/responsive-ui-convergence` | **Date**: 2026-09-11 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-responsive-ui-convergence/spec.md`

## Summary

在不改变校园数据源和路由索引的前提下，收敛教务、课表、信息、邮箱、快速跳转、AI 服务及桌面导航的 UI。实现采用清源设计系统既有组件和令牌：页面外层受视口约束，长列表/详情改为卡片内滚动；宽屏使用高密度横向布局，窄屏按真实可用宽度降级。已获学分改用独立成绩快照中已通过课程的合计；信息刷新服务新增一次刷新全部启用渠道的原子入口。

## Technical Context

**Language/Version**: Dart 3.12.0，Flutter >= 3.44.0

**Primary Dependencies**: Flutter Widgets、仓库内 Qingyuan `Yh*` 组件、现有 Provider/服务层与持久化组件

**Storage**: 现有本地应用数据与安全存储；本功能不新增持久化格式

**Testing**: `flutter_test` Widget/模型/服务测试，Windows Debug 真实渲染检查

**Target Platform**: Windows 桌面为主要回归平台，同时保持 Android/iOS/macOS/Linux 的 Flutter 响应式兼容

**Project Type**: 多平台 Flutter 应用

**Performance Goals**: 常规列表滚动保持流畅；50 封邮件与完整周课表在一次布局周期内无明显卡顿

**Constraints**: 只读校园数据；不加载邮件远端内容；不引入 Material/Cupertino 视觉组件；不改变现有导航 destination 索引

**Scale/Scope**: 7 个用户入口、约 15 个页面/模型/服务文件及对应 Widget/单元测试

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] 用户价值优先：规格包含 5 个可独立验证故事、17 项需求与 6 项可衡量标准。
- [x] 设计系统一致性：实现只复用 Qingyuan facade、组件、图标和设计令牌。
- [x] 测试先行：先新增已获学分、全部渠道刷新、课表溢出与响应式布局回归测试。
- [x] 本地数据与最小权限：不新增远端写入；邮件只展示本地安全文本。
- [x] 可审查交付：规格、计划、任务与测试建立 FR 映射，分支目标为 `develop`。
- [x] Phase 1 复核：数据模型和 UI 契约未引入宪章例外。

## Project Structure

### Documentation (this feature)

```text
specs/003-responsive-ui-convergence/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
├── contracts/
│   └── ui-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/
├── app.dart
├── models/academic_eams/grades.dart
├── services/info_refresh_service.dart
├── design/qingyuan/navigation/yh_navigation.dart
└── pages/
    ├── academic_*.dart
    ├── course_schedule_*.dart
    ├── info_*.dart
    ├── email_*.dart
    ├── quick_links_*.dart
    └── ai_services_page.dart

test/
├── academic_*_test*.dart
├── course_schedule_page_test.dart
├── info_*_test.dart
├── email_*_test.dart
├── quick_links_page_test.dart
├── ai_services_page_test.dart
└── widget_test_shell.dart
```

**Structure Decision**: 保持现有按页面、模型、服务和 Qingyuan 设计系统分层的单一 Flutter 工程；页面只编排视图，学分计算留在成绩模型，跨来源刷新留在服务层，通用导航 footer 能力留在设计系统。

## Complexity Tracking

无宪章例外。
