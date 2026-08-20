/*
 * 校园卡详情交易呈现 — 记录网格、分页与日期文本处理
 * @Project : SSPU-AllinOne
 * @File : home_campus_card_detail_transactions.dart
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

part of 'home_page.dart';

/// 承载校园卡交易记录的紧凑呈现、分页与格式化辅助函数。
extension _CampusCardDetailTransactions on _CampusCardDetailPageState {
  /// 构建当前筛选结果，空结果不拉伸为全宽大卡。
  Widget _buildTransactionPanel(YhTheme theme) {
    if (_filteredRecords.isEmpty) {
      return _CampusCardEmptyRecoveryPanel(onClearFilters: _clearFilters);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final singleColumn =
                constraints.maxWidth <=
                theme.breakpoint.medium +
                    theme.layout.inlineControlWidth -
                    theme.spacing.xl2;
            final gap = theme.spacing.s;
            final cardWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - gap * 2) / 3;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var index = 0; index < _pagedRecords.length; index++)
                  SizedBox(
                    width: cardWidth,
                    child: _buildTransactionCard(
                      theme,
                      _pagedRecords[index],
                      index,
                    ),
                  ),
              ],
            );
          },
        ),
        if (_totalPages > 1) ...[
          SizedBox(height: theme.spacing.m),
          _buildPagination(theme),
        ],
      ],
    );
  }

  /// 构建一条金额、收支方向和时间均可快速扫读的交易卡。
  Widget _buildTransactionCard(
    YhTheme theme,
    CampusCardTransactionRecord record,
    int index,
  ) {
    final directionLabel = _directionLabel(record);
    return YhCard(
      key: Key('campus-card-transaction-$index'),
      semanticLabel:
          '$directionLabel，${_transactionTitle(record)}，${_formatSignedMoney(record.amount)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              YhStatusPill(
                label: directionLabel,
                kind: record.isIncome
                    ? YhStatusKind.success
                    : YhStatusKind.info,
              ),
              SizedBox(width: theme.spacing.s),
              Expanded(
                child: Text(
                  _formatTransactionTime(record.occurredAt),
                  textAlign: TextAlign.end,
                  style: theme.typography.caption.copyWith(
                    color: theme.color.muted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.m),
          Text(
            _transactionTitle(record),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.h3.copyWith(
              fontWeight: theme.typography.semibold,
            ),
          ),
          SizedBox(height: theme.spacing.s),
          Text(
            _transactionDetail(record),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.small.copyWith(color: theme.color.muted),
          ),
          SizedBox(height: theme.spacing.l),
          Text(
            _formatSignedMoney(record.amount),
            textAlign: TextAlign.end,
            style: theme.typography.h2.copyWith(
              color: theme.color.serviceFinance,
              fontFamily: YhTypographyTokens.fontFamilyMono,
              fontWeight: theme.typography.semibold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建保持 48dp 图标命中区的交易分页控制。
  Widget _buildPagination(YhTheme theme) {
    final statusText =
        '第 ${_currentPage + 1} / $_totalPages 页 · 共 ${_filteredRecords.length} 条';
    return SizedBox(
      height: theme.control.regular,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          YhIconButton(
            key: const Key('campus-card-prev-page'),
            icon: YhIcons.back,
            semanticLabel: '上一页',
            onTap: _currentPage > 0 ? _showPreviousPage : null,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: theme.layout.inlineControlWidth,
              maxWidth: theme.layout.popoverWidth,
            ),
            child: Text(
              statusText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.caption,
            ),
          ),
          YhIconButton(
            key: const Key('campus-card-next-page'),
            icon: YhIcons.chevronRight,
            semanticLabel: '下一页',
            onTap: _currentPage < _totalPages - 1 ? _showNextPage : null,
          ),
        ],
      ),
    );
  }

  /// 解析严格的年月日输入；空值代表未设置筛选边界。
  DateTime? _parseDate(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(trimmedText);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// 将交易文本解析为仅用于日期筛选的本地日期。
  DateTime? _parseRecordDate(String text) {
    final value = _parseRecordDateTime(text);
    return value == null ? null : DateTime(value.year, value.month, value.day);
  }

  /// 解析校园卡记录常见的日期时间文本。
  DateTime? _parseRecordDateTime(String text) {
    final match = RegExp(
      r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?',
    ).firstMatch(text.trim());
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.tryParse(match.group(4) ?? '') ?? 0,
      int.tryParse(match.group(5) ?? '') ?? 0,
    );
  }

  /// 将原始交易时间转换为适合当前账本扫读的相对文本。
  String _formatTransactionTime(String raw) {
    final match = RegExp(
      r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?',
    ).firstMatch(raw.trim());
    if (match == null) return raw;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final hour = match.group(4)?.padLeft(2, '0');
    final minute = match.group(5);
    final time = hour == null || minute == null ? '' : ' $hour:$minute';
    if (year == _now.year && month == _now.month && day == _now.day) {
      return '今天$time';
    }
    return '$month 月 $day 日$time';
  }

  /// 格式化日期输入所需的固定年月日文本。
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// 格式化页面元信息使用的时刻。
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 格式化过期快照提示使用的完整时间。
  String _formatFullTime(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')} 月 '
        '${dateTime.day.toString().padLeft(2, '0')} 日 '
        '${_formatTime(dateTime)}';
  }

  /// 格式化余额为固定两位小数的人民币文本。
  String _formatMoney(double value) => '¥${value.toStringAsFixed(2)}';

  /// 格式化交易金额的收支正负号与两位小数。
  String _formatSignedMoney(double value) {
    final sign = value >= 0 ? '+' : '−';
    return '$sign¥${value.abs().toStringAsFixed(2)}';
  }

  /// 依据原始金额方向生成可读的交易标签。
  String _directionLabel(CampusCardTransactionRecord record) {
    if (record.isIncome) return '收入';
    if (record.isExpense) return '支出';
    return '未知';
  }

  /// 合并原始商户与交易类型，缺失时提供稳定回退标题。
  String _transactionTitle(CampusCardTransactionRecord record) {
    final explicit = record.title?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final parts = [record.merchant, record.type]
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? '交易' : parts.join(' · ');
  }

  /// 合并原始支付方式与状态，缺失时避免制造推测性详情。
  String _transactionDetail(CampusCardTransactionRecord record) {
    final parts = [record.paymentMethod, record.status]
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return parts.isEmpty ? '校园卡 · 已记录' : parts.join(' · ');
  }
}

/// 呈现本地筛选无结果时左锚定、内容高的交易恢复条。
class _CampusCardEmptyRecoveryPanel extends StatelessWidget {
  /// 创建本地交易筛选的空结果恢复条。
  ///
  /// :param onClearFilters: 恢复默认本地筛选的操作。
  const _CampusCardEmptyRecoveryPanel({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = context.yhTheme;
    final compact = MediaQuery.sizeOf(context).width < theme.breakpoint.medium;
    final action = YhButton(
      label: '清除筛选',
      variant: YhButtonVariant.secondary,
      onTap: onClearFilters,
    );
    final description = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('当前范围没有交易记录', style: theme.typography.h3),
        ),
        SizedBox(height: theme.spacing.xs),
        Text(
          '余额与卡状态仍然有效；清除日期或切换收支方向即可恢复默认范围。',
          style: theme.typography.small.copyWith(color: theme.color.muted),
        ),
      ],
    );
    final icon = ExcludeSemantics(
      child: Icon(
        YhIcons.finance,
        size: theme.spacing.l,
        color: theme.color.brandStrong,
      ),
    );

    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.layout.formContentWidth),
        child: YhCard(
          key: const Key('campus-card-empty-panel'),
          padding: EdgeInsets.all(theme.spacing.m),
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        icon,
                        SizedBox(width: theme.spacing.s),
                        Expanded(child: description),
                      ],
                    ),
                    SizedBox(height: theme.spacing.m),
                    action,
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    icon,
                    SizedBox(width: theme.spacing.s),
                    Expanded(child: description),
                    SizedBox(width: theme.spacing.m),
                    action,
                  ],
                ),
        ),
      ),
    );
  }
}
