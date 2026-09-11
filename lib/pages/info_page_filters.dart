/*
 * 资讯页面筛选规则与筛选状态计算
 * @Project : SSPU-AllinOne
 * @File : info_page_filters.dart
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

part of 'info_page.dart';

enum _InfoPrimarySource { all, schoolWebsite, wechat }

Future<void> _filterInfoPageByEnabledChannels(_InfoPageState state) async {
  final messageSnapshot = List<MessageItem>.of(state._allMessages);
  final allConfigs = [...departmentChannels, ...teachingChannels];
  final enabledCache = <String, bool>{};
  for (final config in allConfigs) {
    enabledCache[config.id] = await state._stateService.isChannelEnabled(
      config.id,
      defaultValue: config.defaultEnabled,
    );
  }

  final categoryEnabledCache = <String, bool>{};
  for (final entry in channelSubcategories.entries) {
    for (final sub in entry.value) {
      categoryEnabledCache[sub.category.name] = await state._stateService
          .isCategoryEnabled(sub.category.name);
    }
  }

  final wechatPublicEnabled = await state._stateService.isWechatPublicEnabled();
  final wechatServiceEnabled = await state._stateService
      .isWechatServiceEnabled();

  final mpEnabledCache = <String, bool>{};
  for (final msg in messageSnapshot) {
    if (msg.mpBookId != null && !mpEnabledCache.containsKey(msg.mpBookId)) {
      mpEnabledCache[msg.mpBookId!] = await state._stateService
          .isMpNotificationEnabled(msg.mpBookId!);
    }
  }

  final visibleMessages = messageSnapshot.where((msg) {
    if (msg.sourceType == MessageSourceType.wechatPublic) {
      if (!wechatPublicEnabled) return false;
      if (msg.mpBookId != null) {
        return mpEnabledCache[msg.mpBookId] ?? true;
      }
      return true;
    }
    if (msg.sourceType == MessageSourceType.wechatService) {
      return wechatServiceEnabled;
    }

    final channelId = _infoCategoryToChannelId[msg.category];
    if (channelId != null) {
      if (!(enabledCache[channelId] ?? false)) return false;
      final categoryName = msg.category.name;
      if (categoryEnabledCache.containsKey(categoryName)) {
        return categoryEnabledCache[categoryName]!;
      }
      return true;
    }
    return true;
  }).toList();

  visibleMessages.sort((a, b) {
    final tsA = a.timestamp ?? _infoDateToTimestamp(a.date);
    final tsB = b.timestamp ?? _infoDateToTimestamp(b.date);
    return tsB.compareTo(tsA);
  });
  state._allMessages
    ..clear()
    ..addAll(visibleMessages);

  state._applyFilters();
}

int _infoDateToTimestamp(String date) {
  try {
    final dt = DateTime.parse(date);
    return dt.millisecondsSinceEpoch;
  } catch (_) {
    return 0;
  }
}

void _applyInfoPageFilters(_InfoPageState state) {
  state._filteredMessages = state._allMessages.where((msg) {
    if (state._searchQuery.isNotEmpty &&
        !_infoSearchText(msg).contains(state._searchQuery.toLowerCase())) {
      return false;
    }
    if (!_matchesInfoPrimarySource(msg, state._primarySource)) return false;
    if (state._filterSourceType != null &&
        msg.sourceType != state._filterSourceType) {
      return false;
    }
    if (state._filterSourceName != null &&
        msg.sourceName != state._filterSourceName) {
      return false;
    }
    if (state._filterWechatMpName != null &&
        _infoWechatMpName(msg) != state._filterWechatMpName) {
      return false;
    }
    if (state._filterCategory != null &&
        msg.category != state._filterCategory) {
      return false;
    }
    if (state._filterUnreadOnly && state._stateService.isRead(msg.id)) {
      return false;
    }
    return true;
  }).toList();

  state._currentPage = 0;
  state._refreshView();
}

String _infoSearchText(MessageItem message) => [
  message.title,
  message.sourceType.label,
  message.sourceName.label,
  message.category.label,
  message.mpName ?? '',
].join(' ').toLowerCase();

bool _matchesInfoPrimarySource(
  MessageItem message,
  _InfoPrimarySource source,
) => switch (source) {
  _InfoPrimarySource.all => true,
  _InfoPrimarySource.schoolWebsite =>
    message.sourceType == MessageSourceType.schoolWebsite,
  _InfoPrimarySource.wechat =>
    message.sourceType == MessageSourceType.wechatPublic ||
        message.sourceType == MessageSourceType.wechatService,
};

String _infoWechatMpName(MessageItem message) {
  final mpName = message.mpName?.trim();
  if (mpName == null || mpName.isEmpty) return '公众号名称未知';
  return mpName;
}

List<MessageItem> _getPagedInfoMessages(_InfoPageState state) {
  final startIndex = state._currentPage * _InfoPageState._pageSize;
  final endIndex = min(
    startIndex + _InfoPageState._pageSize,
    state._filteredMessages.length,
  );
  if (startIndex >= state._filteredMessages.length) return [];
  return state._filteredMessages.sublist(startIndex, endIndex);
}

int _getInfoTotalPages(_InfoPageState state) =>
    (state._filteredMessages.length / _InfoPageState._pageSize).ceil().clamp(
      1,
      9999,
    );

List<String> _getInfoAvailableWechatMpNames(_InfoPageState state) {
  final mpNames = state._allMessages
      .where((message) => message.sourceType == MessageSourceType.wechatPublic)
      .map(_infoWechatMpName)
      .toSet()
      .toList();
  mpNames.sort();
  return mpNames;
}
