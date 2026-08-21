<!--
  清源关于与法律阅读密度设计自评审与冻结记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-about-legal-reading-density-v01.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

# 关于与法律阅读密度评审 v01

日期：2026-08-19  
分支：`feature/design-language-spec`  
验收：跳过 SSIM；以多尺寸截图完整性、人工逐屏检查、键鼠/触控协同与异常恢复为准。

## 审查证据

- 当前原型的应用外壳已在 1600×1000 捕获，确认导航、标题、来源条与主要操作的层级可以保留；本批仅收束正文表面，不重做全局外壳。
- 当前 Windows Flutter 候选 `build/visual/windows/settings.about--content--light--1600x1000.png` 中，三项构建信息位于大约整屏高度的卡片顶部，卡片余量无内容。
- 当前 Windows Flutter 候选 `build/visual/windows/legal.privacy--content--light--1600x1000.png` 中，三个短章节只占卡片顶部，正文实际可读列之外与下方均被无信息边框包围。
- 360×800 的对应候选确认标题、来源、主要行动及第一项内容未裁切；问题是宽屏空框和短内容最小高度，不能用删除窄屏操作解决。

审查截图保存于：

- `build/product-design-audit-2026-08-19/17-about-legal-reference-1600x1000.png`。
- `build/visual/windows/settings.about--content--light--1600x1000.png`。
- `build/visual/windows/legal.privacy--content--light--1600x1000.png`。
- 两者对应的 `360x800` 候选。

## 决议

采用 [`about-legal-reading-density-v01.md`](../patterns/about-legal-reading-density-v01.md)：关于页账本切换为内容高、表单宽左锚定；法律页删除“填满可视区”的最小高度，并让章节表面只包住现有阅读列。

保留所有版本、设计、许可、返回、更多操作、外链确认、加载、错误重试、正文选择与语义路径。此次改变不增加业务功能、不变更数据访问，也不修改法律正文或其阅读宽度。

## 实施后核验要求

1. 添加宽屏 widget 回归，证明关于账本与短法律正文不再扩展到页面主体宽度/高度。
2. 运行 `test/settings_about_page_test.dart` 与 `test/privacy_policy_page_test.dart`。
3. 重新采集关于 content/error 与法律 content/loading/error 的四档、亮暗候选图；检查内容表面自然收束、长文可滚动、窄屏无裁切。
4. 通过 `flutter analyze`、设计系统门禁、样式表门禁和 `git diff --check`。

## 冻结

上述视觉和交互基线已在实现前冻结。Flutter 实现只能调整布局约束与测试钩子；不得借此更改文案、操作语义、路由、加载器或服务契约。

## 实施后核验

| 项目 | 结果 |
| --- | --- |
| 关于/法律行为回归 | `flutter test test/settings_about_page_test.dart test/privacy_policy_page_test.dart`，26 项通过；新增宽屏账本与短法律正文的尺寸回归。 |
| Flutter 视觉候选 | `build/visual/about-legal-reading-density-v01` 共 128 张：关于 56 张（7 态），法律 72 张（三文档 × loading/content/error）。 |
| 视口与主题 | 每个场景均覆盖 360×800、768×900、1200×900、1600×1000 与亮暗主题；128 张 PNG 的文件名和物理尺寸均通过检查。 |
| 人工抽检 | 四档关于 content、四档隐私 content，以及关于 error/operation-locked、法律 loading/error 的亮暗候选均检查。账本和短正文均按内容收束，360 继续自然滚动且未出现横向裁切。 |
| 静态门禁 | `flutter analyze`、清源设计系统/样式表契约与 `git diff --check` 均通过。 |

视觉清单因此扩展为 193 个页面/状态组合；五个平台的下一轮完整矩阵目标随之更新为 1544 张 PNG。此处证据仅证明本机 Windows 目标渲染候选；其余四个平台仍需真实 runner 复核。
