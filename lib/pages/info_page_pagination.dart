/*
 * 信息页分页控件 — 桌面与移动端单行分页
 * @Project : SSPU-AllinOne
 * @File : info_page_pagination.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

part of 'info_page.dart';

Widget _buildInfoMobilePagination(_InfoPageState state, FluentThemeData theme) {
  return _buildInfoPaginationRow(
    state,
    theme,
    key: const Key('info-mobile-pagination'),
    height: 36,
    statusText:
        '${state._currentPage + 1}/${state._totalPages} · '
        '${state._filteredMessages.length} 条',
  );
}

Widget _buildInfoPagination(_InfoPageState state, FluentThemeData theme) {
  return _buildInfoPaginationRow(
    state,
    theme,
    key: const Key('info-regular-pagination'),
    height: 36,
    statusText:
        '第 ${state._currentPage + 1} / ${state._totalPages} 页'
        ' · 共 ${state._filteredMessages.length} 条',
  );
}

Widget _buildInfoPaginationRow(
  _InfoPageState state,
  FluentThemeData theme, {
  required Key key,
  required double height,
  required String statusText,
}) {
  final colors = state.context.fluentColors;

  return SizedBox(
    key: key,
    height: height,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _InfoCompactIconButton(
          tooltip: '上一页',
          icon: FluentIcons.chevronLeft,
          size: 32,
          iconSize: 14,
          onPressed: state._currentPage > 0
              ? () => state._setCurrentPage(state._currentPage - 1)
              : null,
        ),
        Tooltip(
          message: '点击跳转到指定页',
          child: FluentHoverButton(
            onPressed: () => state._showPageJumpDialog(),
            builder: (context, states) {
              return Container(
                height: 32,
                alignment: Alignment.center,
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 260),
                padding: const EdgeInsets.symmetric(
                  horizontal: FluentSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: states.isHovered
                      ? colors.subtleBackgroundHover
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(FluentRadius.medium),
                ),
                child: Text(
                  statusText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.typography.caption?.copyWith(
                    decoration: states.isHovered
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              );
            },
          ),
        ),
        _InfoCompactIconButton(
          tooltip: '下一页',
          icon: FluentIcons.chevronRight,
          size: 32,
          iconSize: 14,
          onPressed: state._currentPage < state._totalPages - 1
              ? () => state._setCurrentPage(state._currentPage + 1)
              : null,
        ),
      ],
    ),
  );
}

Future<void> _showInfoPageJumpDialog(_InfoPageState state) async {
  final controller = TextEditingController();
  final result = await showDialog<int>(
    context: state.context,
    builder: (ctx) => FluentDialog(
      title: const Text('跳转到指定页'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('当前第 ${state._currentPage + 1} 页，共 ${state._totalPages} 页'),
          const SizedBox(height: FluentSpacing.s),
          FluentTextField(
            controller: controller,
            placeholder: '输入页码 (1-${state._totalPages})',
            keyboardType: TextInputType.number,
            autofocus: true,
            onSubmitted: (_) {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= state._totalPages) {
                Navigator.of(ctx).pop(page - 1);
              }
            },
          ),
        ],
      ),
      actions: [
        FluentButton.outline(
          child: const Text('取消'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        FluentButton.primary(
          child: const Text('跳转'),
          onPressed: () {
            final page = int.tryParse(controller.text);
            if (page != null && page >= 1 && page <= state._totalPages) {
              Navigator.of(ctx).pop(page - 1);
            }
          },
        ),
      ],
    ),
  );
  controller.dispose();

  if (result != null && state.mounted) {
    state._setCurrentPage(result);
  }
}
