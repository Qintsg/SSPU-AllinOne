/*
 * 关于页开源许可数据 — 项目清单与许可证说明
 * @Project : SSPU-AllinOne
 * @File : about_open_source_data.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'about_page.dart';

/// 使用/参考的开源项目列表。
/// 若后续用户没有明确说明，不得修改此内容。
const List<_OpenSourceProject> _openSourceProjects = [
  _OpenSourceProject(
    name: 'Flutter',
    description: '跨平台 UI 框架与渲染基础能力',
    license: 'BSD-3-Clause',
    url: 'https://flutter.dev',
  ),
  _OpenSourceProject(
    name: 'fluentui_system_icons',
    description: 'YhIcons 语义图标门面的底层字形资源',
    license: 'MIT',
    url: 'https://pub.dev/packages/fluentui_system_icons',
  ),
  _OpenSourceProject(
    name: 'shared_preferences',
    description: '本地持久化存储',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/shared_preferences',
  ),
  _OpenSourceProject(
    name: 'path_provider',
    description: '平台应用支持目录解析',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/path_provider',
  ),
  _OpenSourceProject(
    name: 'crypto',
    description: 'SHA-256 等哈希算法',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/crypto',
  ),
  _OpenSourceProject(
    name: 'flutter_secure_storage',
    description: '系统安全存储凭据保存',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/flutter_secure_storage',
  ),
  _OpenSourceProject(
    name: 'local_auth',
    description: '系统 PIN / 生物识别快速验证',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/local_auth',
  ),
  _OpenSourceProject(
    name: 'url_launcher',
    description: '打开外部链接',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/url_launcher',
  ),
  _OpenSourceProject(
    name: 'open_filex',
    description: '打开本地文件、安装包或所在文件夹',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/open_filex',
  ),
  _OpenSourceProject(
    name: 'window_manager',
    description: 'Flutter 桌面窗口管理',
    license: 'MIT',
    url: 'https://pub.dev/packages/window_manager',
  ),
  _OpenSourceProject(
    name: 'tray_manager',
    description: '系统托盘图标管理',
    license: 'MIT',
    url: 'https://pub.dev/packages/tray_manager',
  ),
  _OpenSourceProject(
    name: 'dio',
    description: '强大的 HTTP 客户端库',
    license: 'MIT',
    url: 'https://pub.dev/packages/dio',
  ),
  _OpenSourceProject(
    name: 'local_notifier',
    description: 'Windows 本地系统通知推送',
    license: 'MIT',
    url: 'https://pub.dev/packages/local_notifier',
  ),
  _OpenSourceProject(
    name: 'html',
    description: 'HTML 解析库',
    license: 'MIT',
    url: 'https://pub.dev/packages/html',
  ),
  _OpenSourceProject(
    name: 'gbk_codec',
    description: 'GBK / GB2312 页面解码',
    license: 'MIT',
    url: 'https://pub.dev/packages/gbk_codec',
  ),
  _OpenSourceProject(
    name: 'flutter_animate',
    description: '页面入场与微交互动效',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/flutter_animate',
  ),
  _OpenSourceProject(
    name: 'flutter_inappwebview',
    description: '内嵌 WebView 与 WebView2 能力',
    license: 'Apache-2.0',
    url: 'https://pub.dev/packages/flutter_inappwebview',
  ),
  _OpenSourceProject(
    name: 'package_info_plus',
    description: '应用版本与包信息读取',
    license: 'BSD-3-Clause',
    url: 'https://pub.dev/packages/package_info_plus',
  ),
  _OpenSourceProject(
    name: 'enough_mail',
    description: '学校邮箱 IMAP / POP / SMTP 协议客户端',
    license: 'MPL-2.0',
    url: 'https://pub.dev/packages/enough_mail',
  ),
  _OpenSourceProject(
    name: 'pdfrx',
    description: '应用内 PDF 查看与 PDF 渲染能力',
    license: 'MIT',
    url: 'https://pub.dev/packages/pdfrx',
  ),
  _OpenSourceProject(
    name: 'pdfrx_engine',
    description: 'PDF 文本抽取与底层 PDFium 封装',
    license: 'MIT',
    url: 'https://pub.dev/packages/pdfrx_engine',
  ),
  _OpenSourceProject(
    name: 'MiSans',
    description: '小米系统字体，数字等宽',
    license: 'MiSans EULA',
    url: 'https://hyperos.mi.com/font/zh',
  ),
];

class _OpenSourceProject {
  const _OpenSourceProject({
    required this.name,
    required this.description,
    required this.license,
    required this.url,
  });

  final String name;
  final String description;
  final String license;
  final String url;

  String get licenseDescription => switch (license) {
    'BSD-3-Clause' => '宽松许可证；使用与分发时保留版权声明、许可文本和免责声明。',
    'MIT' => '宽松许可证；允许使用、复制、修改与分发，需保留版权和许可声明。',
    'Apache-2.0' => '宽松许可证；包含专利授权条款，分发时保留许可证与必要 NOTICE。',
    'MPL-2.0' => '文件级弱 copyleft；若修改 MPL 覆盖文件，需按 MPL 提供对应源代码。',
    'Microsoft Design Guidelines' => '设计指南与品牌资源规则；本项目仅参考界面语言，不声明 Microsoft 背书。',
    'MiSans EULA' => '字体最终用户许可；随应用使用与分发时遵守小米字体许可条款。',
    _ => '请以项目发布的许可证正文为准。',
  };
}
