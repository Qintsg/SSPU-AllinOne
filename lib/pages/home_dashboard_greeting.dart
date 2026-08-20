/*
 * 首页问候短语组件 — 在紧凑视口保持完整的中文阅读断句
 * @Project : SSPU-AllinOne
 * @File : home_dashboard_greeting.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'home_page.dart';

/// 可在不同视口独立编排的首页问候短语。
class _HomeGreetingPhrases {
  const _HomeGreetingPhrases(this.leading, this.focus);

  /// 问候前半句，例如“早上好，”。
  final String leading;

  /// 问候的任务焦点，例如“先看清今天。”。
  final String focus;

  /// 供宽屏及辅助技术使用的完整问候文本。
  String get text => '$leading$focus';
}

/// 紧凑端将首页问候限制为完整阅读短语的换行组件。
class _HomeGreetingPhraseWrap extends StatelessWidget {
  const _HomeGreetingPhraseWrap({
    required this.leading,
    required this.focus,
    required this.style,
  });

  /// 问候前半句。
  final String leading;

  /// 问候任务焦点。
  final String focus;

  /// 标题排版样式。
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Wrap(
        key: const Key('home-greeting-phrases'),
        spacing: 0,
        runSpacing: 0,
        children: [
          Text(leading, style: style, softWrap: false),
          Text(focus, style: style, softWrap: false),
        ],
      ),
    );
  }
}
