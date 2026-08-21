/* 渠道业务图标到清源语义图标的唯一映射。 */

import '../design/qingyuan/qingyuan_ui.dart';
import '../models/channel_config.dart';

IconData resolveChannelIcon(ChannelIcon icon) => switch (icon) {
  ChannelIcon.chat => YhIcons.chat,
  ChannelIcon.contact => YhIcons.contact,
  ChannelIcon.database => YhIcons.database,
  ChannelIcon.education => YhIcons.education,
  ChannelIcon.event => YhIcons.event,
  ChannelIcon.globe => YhIcons.globe,
  ChannelIcon.home => YhIcons.home,
  ChannelIcon.library => YhIcons.library,
  ChannelIcon.lock => YhIcons.lock,
  ChannelIcon.mail => YhIcons.mail,
  ChannelIcon.megaphone => YhIcons.megaphone,
  ChannelIcon.news => YhIcons.news,
  ChannelIcon.people => YhIcons.people,
  ChannelIcon.settings => YhIcons.settings,
  ChannelIcon.video => YhIcons.video,
};
