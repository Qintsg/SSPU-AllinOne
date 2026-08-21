/*
 * 清源组件工作台视觉面板 — 按冻结参考稿组织六组组件契约
 * @Project : SSPU-AllinOne
 * @File : qingyuan_component_visual_panels.dart
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

import 'package:sspu_allinone/design/qingyuan/qingyuan_ui.dart';

part 'qingyuan_component_workbench.dart';

/// 构建按响应式列数排列的操作组件工作台。
Widget componentActionsPanel() =>
    _componentPanel('操作组件', '行动、选择与进度控件共享明确层级，危险与禁用状态不靠尺寸夸张。', [
      _ComponentGroup(
        title: '按钮与行动',
        summary: '主要、次要、禁用与图标行动',
        child: Wrap(
          spacing: YhTheme.light.spacing.s,
          runSpacing: YhTheme.light.spacing.s,
          children: [
            YhButton(label: '主要操作', onTap: () {}),
            YhButton(
              label: '次要操作',
              variant: YhButtonVariant.secondary,
              onTap: () {},
            ),
            const YhButton(
              label: '禁用操作',
              variant: YhButtonVariant.text,
              minWidth: 96,
              disabled: true,
            ),
            YhIconButton(
              icon: YhIcons.refresh,
              semanticLabel: '刷新',
              onTap: () {},
            ),
            YhFab(
              icon: YhIcons.add,
              semanticLabel: '新建',
              label: '新建',
              onTap: () {},
            ),
          ],
        ),
      ),
      _ComponentGroup(
        title: '选择与开关',
        summary: '单选、复选和分段选择保持同一命中节奏',
        child: Wrap(
          spacing: YhTheme.light.spacing.s,
          runSpacing: YhTheme.light.spacing.s,
          children: [
            YhSegmented<String>(
              options: const [
                YhSegmentedOption(value: 'day', label: '日'),
                YhSegmentedOption(value: 'week', label: '周'),
                YhSegmentedOption(value: 'month', label: '月'),
              ],
              value: 'week',
              onChanged: (_) {},
            ),
            YhChip(label: '已选择', selected: true, onTap: () {}),
            YhChip(label: '筛选项', onTap: () {}),
            YhSwitch(value: true, semanticLabel: '通知', onChanged: (_) {}),
            YhCheckbox(label: '同意协议', value: true, onChanged: (_) {}),
            YhRadio<String>(
              label: '校内服务',
              value: 'campus',
              groupValue: 'campus',
              onChanged: (_) {},
            ),
          ],
        ),
      ),
      _ComponentGroup(
        title: '连续进度',
        summary: '滑块与步骤状态表达当前位置和下一步',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            YhSlider(value: 0.68, label: '透明度', onChanged: (_) {}),
            SizedBox(height: YhTheme.light.spacing.s),
            YhStepper(
              steps: const ['填写', '确认', '完成'],
              currentStep: 1,
              onStepSelected: (_) {},
            ),
          ],
        ),
      ),
    ]);

/// 构建按响应式列数排列的输入组件工作台。
Widget componentInputsPanel() => _componentPanel(
  '输入组件',
  '持续标签、帮助文本与错误说明共同保留输入上下文，不把占位符当标签。',
  [
    _ComponentGroup(
      title: '文字输入',
      summary: '普通、搜索与多行输入',
      wide: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final theme = context.yhTheme;
          final compact = constraints.maxWidth < theme.layout.formContentWidth;
          final fieldWidth = compact
              ? constraints.maxWidth
              : (constraints.maxWidth - theme.spacing.s) / 2;
          return Wrap(
            spacing: theme.spacing.s,
            runSpacing: theme.spacing.s,
            children: [
              SizedBox(
                width: fieldWidth,
                child: const YhTextField(label: '姓名', hint: '请输入姓名'),
              ),
              SizedBox(width: fieldWidth, child: const _LabeledSearch()),
              SizedBox(
                width: constraints.maxWidth,
                child: const YhTextarea(label: '备注', hint: '补充说明', maxLines: 2),
              ),
            ],
          );
        },
      ),
    ),
    _ComponentGroup(
      title: '结构化选择',
      summary: '学期与日期使用持续可见标签',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YhSelect<String>(
            label: '学期',
            options: const [
              YhSelectOption(value: '2026-summer', label: '2026 夏季学期'),
              YhSelectOption(value: '2026-spring', label: '2026 春季学期'),
            ],
            value: '2026-summer',
            onChanged: (_) {},
          ),
          SizedBox(height: YhTheme.light.spacing.m),
          YhDatePicker(label: '查询日期', value: '2026-07-19', onTap: () {}),
        ],
      ),
    ),
    _ComponentGroup(
      title: '验证码与错误',
      summary: '定长输入和错误恢复靠近对应字段',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OtpPreview(),
          SizedBox(height: YhTheme.light.spacing.m),
          const _ErrorEmailPreview(),
        ],
      ),
    ),
  ],
);

/// 构建按响应式列数排列的反馈组件工作台。
Widget componentFeedbackPanel() =>
    _componentPanel('容器与反馈', '容器只组织真实上下文；提示、空状态和确认行动说明现在发生什么。', [
      _ComponentGroup(
        title: '内容容器',
        summary: '卡片、磁贴、列表与折叠说明',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Builder(
              builder: (context) => YhCard(
                padding: EdgeInsets.all(context.yhTheme.spacing.m),
                radius: context.yhTheme.radius.m,
                child: const Text('用于组织关联内容的清源卡片'),
              ),
            ),
            SizedBox(height: YhTheme.light.spacing.s),
            const YhTile(
              child: SizedBox(width: double.infinity, child: Text('可选择的内容磁贴')),
            ),
            SizedBox(height: YhTheme.light.spacing.s),
            Builder(
              builder: (context) => YhCard(
                padding: EdgeInsets.zero,
                radius: context.yhTheme.radius.m,
                child: const YhListItem(title: '校园通知', subtitle: '刚刚更新'),
              ),
            ),
            SizedBox(height: YhTheme.light.spacing.s),
            const YhAccordion(
              title: '查看说明',
              content: Text('折叠内容遵循清源间距与焦点规范。'),
              initiallyExpanded: true,
            ),
          ],
        ),
      ),
      _ComponentGroup(
        title: '即时反馈',
        summary: '状态横幅、保存 Toast 与加载骨架',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const YhBanner(text: '数据已在 09:30 更新'),
            SizedBox(height: YhTheme.light.spacing.s),
            YhToast(message: '设置已保存', actionLabel: '撤销', onAction: () {}),
            SizedBox(height: YhTheme.light.spacing.s),
            const YhSkeleton(),
          ],
        ),
      ),
      _ComponentGroup(
        title: '空状态与确认',
        summary: '没有内容时给出方向，危险决定保留取消',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const YhEmptyState(
              icon: YhIcons.inbox,
              title: '暂无内容',
              message: '完成同步后将在这里显示。',
              compact: true,
            ),
            SizedBox(height: YhTheme.light.spacing.s),
            YhDialog(
              title: '确认操作',
              content: const Text('该操作会更新本地显示设置。'),
              actions: [
                YhButton(
                  label: '取消',
                  variant: YhButtonVariant.secondary,
                  onTap: () {},
                ),
                YhButton(label: '确认', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    ]);

/// 构建按响应式列数排列的导航组件工作台。
Widget componentNavigationPanel() =>
    _componentPanel('导航组件', '目的地、页内分段和分页共享清晰选中态，空间变化不改变顺序。', [
      _ComponentGroup(
        title: '页内导航',
        summary: '标签与分页保留当前上下文',
        wide: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            YhTabs<String>(
              tabs: const [
                YhTab(value: 'overview', label: '总览', icon: YhIcons.home),
                YhTab(value: 'detail', label: '详情', icon: YhIcons.info),
              ],
              value: 'overview',
              onChanged: (_) {},
            ),
            SizedBox(height: YhTheme.light.spacing.s),
            YhPagination(
              page: 3,
              pageCount: 8,
              showBoundaryPages: false,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
      _ComponentGroup(
        title: '紧凑目的地',
        summary: '底栏以同一顺序表达三个主目的地',
        child: YhBottomNav(
          items: const [
            YhNavigationItem(icon: YhIcons.home, label: '主页'),
            YhNavigationItem(icon: YhIcons.academic, label: '教务'),
            YhNavigationItem(icon: YhIcons.calendar, label: '课表'),
          ],
          index: 0,
          onChanged: (_) {},
        ),
      ),
      _ComponentGroup(
        title: '纵向目的地',
        summary: '空间充足时切换为导航轨',
        child: SizedBox(
          height: YhTheme.light.layout.bottomNavigationHeight * 3,
          child: YhNavRail(
            items: const [
              YhNavigationItem(icon: YhIcons.home, label: '主页'),
              YhNavigationItem(icon: YhIcons.settings, label: '设置'),
            ],
            index: 0,
            onChanged: (_) {},
          ),
        ),
      ),
    ]);

/// 构建按响应式列数排列的数据组件工作台。
Widget componentDataPanel() =>
    _componentPanel('数据展示', '指标、进度、来源和时间共同出现，数值不脱离证据上下文。', [
      _ComponentGroup(
        title: '状态与身份',
        summary: '数量、运行状态和用户身份使用紧凑标记',
        child: Wrap(
          spacing: YhTheme.light.spacing.s,
          runSpacing: YhTheme.light.spacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            YhBadge(label: '12'),
            YhStatusPill(label: '运行正常', kind: YhStatusKind.success),
            YhStatusPill(label: '需要关注', kind: YhStatusKind.warning),
            YhAvatar(semanticLabel: '清源用户', initials: '清'),
          ],
        ),
      ),
      _ComponentGroup(
        title: '指标与进度',
        summary: '比较值与完成度保留解释',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Builder(
              builder: (context) => YhMetricCard(
                label: '平均绩点',
                value: '3.82',
                caption: '较上学期 +0.12',
                padding: EdgeInsets.symmetric(
                  horizontal: context.yhTheme.spacing.m,
                  vertical:
                      context.yhTheme.spacing.m + context.yhTheme.spacing.xs,
                ),
              ),
            ),
            SizedBox(height: YhTheme.light.spacing.s),
            const YhProgress(value: 0.76, showPercent: false),
            SizedBox(height: YhTheme.light.spacing.s),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: YhRing(value: 0.82, label: '培养进度'),
            ),
          ],
        ),
      ),
      _ComponentGroup(
        title: '来源记录',
        summary: '列表项目同时呈现摘要、来源和时间',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            YhFeedItem(
              title: '夏季学期选课确认',
              summary: '请在规定时间内登录教务系统确认选课结果。',
              source: '教务处',
              timestamp: '09:30',
            ),
            YhSourceBadge(label: '学校官网', icon: YhIcons.globe),
          ],
        ),
      ),
    ]);

/// 构建按响应式列数排列的校园域组件工作台。
Widget componentDomainPanel() => _componentPanel(
  '校园域组件',
  '课程、余额、考勤和校园服务保留域色，但不争夺页面结构层级。',
  [
    _ComponentGroup(
      title: '今日与课程',
      summary: '日程先表达时间，再表达课程地点',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YhTodayCard(
            title: '今天',
            subtitle: '7 月 19 日 · 星期日',
            child: Text('2 节课程 · 1 项待办'),
          ),
          SizedBox(height: YhTheme.light.spacing.s),
          Builder(
            builder: (context) => YhCourseBlock(
              name: '高等数学',
              time: '08:00–09:35',
              location: '教学楼 310',
              color: context.yhTheme.color.serviceAcademic,
            ),
          ),
        ],
      ),
    ),
    _ComponentGroup(
      title: '校园服务',
      summary: '余额、快捷入口和更新时间保持同一证据层级',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const YhBalanceModule(
            label: '校园卡余额',
            balance: '¥ 88.00',
            caption: '更新于 09:30',
          ),
          SizedBox(height: YhTheme.light.spacing.s),
          Builder(
            builder: (context) => YhQuickLink(
              icon: YhIcons.library,
              label: '图书馆',
              subtitle: '馆藏与借阅',
              color: context.yhTheme.color.serviceQuickLink,
              width: double.infinity,
              variant: YhQuickLinkVariant.row,
              onTap: () {},
            ),
          ),
        ],
      ),
    ),
    _ComponentGroup(
      title: '消息与考勤',
      summary: '摘要与状态只表达当前事实',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          YhAiMessage(message: '已为你整理今天的课程与待办。', role: YhMessageRole.assistant),
          SizedBox(height: YhTheme.light.spacing.s),
          YhAttendanceItem(
            title: '体育考勤',
            detail: '操场 · 07:30',
            status: '已签到',
            kind: YhStatusKind.success,
          ),
        ],
      ),
    ),
  ],
);
