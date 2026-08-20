<!--
  清源开源许可密度设计自评审与冻结记录
  @Project : SSPU-AllinOne
  @File : 2026-08-19-open-source-license-density-v01.md
  @Author : Qintsg
  @Date : 2026-08-19
-->

# 开源许可密度评审 v01

日期：2026-08-19  
分支：`feature/design-language-spec`  
验收：跳过 SSIM；以多尺寸截图完整性、人工逐屏审查和外链恢复协同为准。

## 审查证据

- 本次重新采集 `build/visual/licenses-audit-v01` 的 40 张候选，覆盖五态、四档视口与亮暗主题。
- 1200×900 与 1600×1000 content 候选中，表格固定四列在左侧结束，`YhCard` 仍延展至页面右侧，形成明显无信息空框。
- 360×800 与 768×900 使用项目卡而非被裁切表格，项目、场景、许可证、说明和外链图标均可见。
- 360 external-error 与 1600 operation-locked 显示错误恢复、焦点和外链互斥正常，本批不改变。

## 决议

采用 [`open-source-license-density-v01.md`](../patterns/open-source-license-density-v01.md)：宽屏表格外卡收束为表格四列内容宽，移动卡片与所有外链状态维持原样。

## 实施后核验要求

1. 添加宽屏尺寸回归，证明表格卡不会占据整个页面主体宽度。
2. 运行许可、外链确认与焦点归还相关测试。
3. 重新采集五态四档亮暗候选并检查无横向裁切。
4. 通过 `flutter analyze`、设计系统/样式表门禁与 `git diff --check`。

## 冻结

本批仅调整表格容器约束；项目数据、许可证含义、移动卡片、外链确认和锁定行为均冻结不变。

## 实施后核验

| 项目 | 结果 |
| --- | --- |
| 许可与外链回归 | `flutter test test/settings_about_page_test.dart`，13 项通过；新增宽屏矩阵宽度回归。 |
| Flutter 视觉候选 | `build/visual/licenses-density-v01`，五态、四档视口、亮暗共 40 张；文件名和物理尺寸均通过检查。 |
| 人工抽检 | 360 content、768 content、1200 content、1600 external-error 均已检查；表格边界精确收束，移动卡片、错误恢复和焦点没有裁切。 |
| 静态门禁 | `flutter analyze`、清源设计系统/样式表契约与 `git diff --check` 均通过。 |

本批证据为本机 Windows 目标候选；其余四个平台仍需真实 runner 验证。
