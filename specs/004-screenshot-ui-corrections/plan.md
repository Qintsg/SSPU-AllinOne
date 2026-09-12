# Implementation Plan: Screenshot-driven UI corrections

## Approach
按页面域分层修正：先修正数据选择与状态映射，再调整 Qingyuan 布局；为每个域补充 widget/unit 回归测试，最后执行多尺寸视觉采集。

## Touch points
- Home: `lib/pages/home_dashboard_content.dart`, `lib/pages/home_dashboard_primary_layout.dart`
- Academic: `lib/pages/academic_overview_content_grid.dart`, `lib/pages/academic_overview_cards.dart`, `lib/pages/academic_page.dart`
- Schedule/terms: `lib/pages/course_schedule_page.dart`, `lib/pages/course_schedule_views.dart`, `lib/services/academic_eams_service.dart`
- Info: `lib/pages/info_page*.dart`
- Email: `lib/pages/email_page.dart`, `lib/pages/email_message_detail_page.dart`, `lib/services/email_gateway.dart`
- Quick links: `lib/pages/quick_links_directory.dart`, `lib/pages/quick_links_presentation.dart`

## Validation
先运行相关测试建立失败基线；实现后运行 dart format、flutter analyze、flutter test、设计系统与 spec-kit 校验，并使用现有视觉采集在四种尺寸核对无溢出。
