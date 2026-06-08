/*
 * 信息页筛选弹窗 — 移动端次级筛选表单
 * @Project : SSPU-AllinOne
 * @File : info_page_filter_dialog.dart
 * @Author : Qintsg
 * @Date : 2026-06-08
 */

part of 'info_page.dart';

Future<void> _showInfoMobileFilterDialog(_InfoPageState state) {
  return showFluentDialog<void>(
    context: state.context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          void applyAndRefreshDialog() {
            state._applyFilters();
            if (context.mounted) setDialogState(() {});
          }

          return FluentDialog(
            title: const Text('筛选消息'),
            content: _buildInfoMobileFilterForm(
              state,
              applyAndRefreshDialog: applyAndRefreshDialog,
            ),
            actions: [
              FluentButton.outline(
                child: const Text('重置'),
                onPressed: () {
                  state._filterSourceType = null;
                  state._filterSourceName = null;
                  state._filterWechatMpName = null;
                  state._filterCategory = null;
                  state._filterUnreadOnly = false;
                  applyAndRefreshDialog();
                },
              ),
              FluentButton.primary(
                child: const Text('完成'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildInfoMobileFilterForm(
  _InfoPageState state, {
  required VoidCallback applyAndRefreshDialog,
}) {
  final availableSourceNames = state._getAvailableSourceNames();
  final availableWechatMpNames = state._getAvailableWechatMpNames();
  final availableCategories = state._getAvailableCategories();
  final wechatSourceSelected =
      state._filterSourceType == MessageSourceType.wechatPublic;

  Widget combo<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: _buildInfoFilterCombo<T>(
        label: label,
        value: value,
        items: items,
        itemLabel: itemLabel,
        onChanged: onChanged,
        enabled: enabled,
        maxWidth: double.infinity,
      ),
    );
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      combo<MessageSourceType>(
        label: '来源类型',
        value: state._filterSourceType,
        items: const [
          MessageSourceType.schoolWebsite,
          MessageSourceType.wechatPublic,
        ],
        itemLabel: (item) => item.label,
        onChanged: (value) {
          state._filterSourceType = value;
          state._filterSourceName = null;
          state._filterWechatMpName = null;
          state._filterCategory = null;
          applyAndRefreshDialog();
        },
      ),
      const SizedBox(height: FluentSpacing.s),
      if (wechatSourceSelected)
        combo<String>(
          label: '公众号名称',
          value: state._filterWechatMpName,
          items: availableWechatMpNames,
          itemLabel: (item) => item,
          enabled: state._filterSourceType != null,
          onChanged: (value) {
            state._filterWechatMpName = value;
            state._filterCategory = null;
            applyAndRefreshDialog();
          },
        )
      else
        combo<MessageSourceName>(
          label: '来源名称',
          value: state._filterSourceName,
          items: availableSourceNames,
          itemLabel: (item) => item.label,
          enabled: state._filterSourceType != null,
          onChanged: (value) {
            state._filterSourceName = value;
            state._filterCategory = null;
            applyAndRefreshDialog();
          },
        ),
      const SizedBox(height: FluentSpacing.s),
      combo<MessageCategory>(
        label: '内容分类',
        value: state._filterCategory,
        items: availableCategories,
        itemLabel: (item) => item.label,
        enabled: !wechatSourceSelected && state._filterSourceName != null,
        onChanged: (value) {
          state._filterCategory = value;
          applyAndRefreshDialog();
        },
      ),
      const SizedBox(height: FluentSpacing.s),
      _buildInfoUnreadToggle(state, compact: false),
    ],
  );
}
