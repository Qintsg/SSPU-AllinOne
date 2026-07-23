(() => {
  const groupMeta = {
    components: ['组件', '◫', 'var(--brand-strong)'],
    global: ['全局', '⌂', 'var(--structural)'],
    home: ['主页', '⌂', 'var(--service-finance)'],
    academic: ['教务', '学', 'var(--service-academic)'],
    schedule: ['课表', '周', 'var(--service-schedule)'],
    info: ['资讯', '讯', 'var(--service-news)'],
    mail: ['邮箱', '邮', 'var(--service-mail)'],
    links: ['入口', '↗', 'var(--service-quicklink)'],
    settings: ['设置', '设', 'var(--brand-strong)'],
    legal: ['法律', '§', 'var(--structural)'],
    external: ['外部内容', '外', 'var(--service-quicklink)'],
  };

  const navigation = [
    ['home', '⌂', '主页'],
    ['academic', '学', '教务'],
    ['schedule', '周', '课表'],
    ['info', '讯', '资讯'],
    ['mail', '邮', '邮箱'],
    ['links', '↗', '入口'],
    ['settings', '设', '设置'],
  ];

  const stateCopy = {
    initial: ['准备好后再开始', '当前还没有读取校园数据。先说明将要访问的来源，再由你决定是否继续。', '开始读取'],
    loading: ['正在读取本地快照', '先恢复已经保存在设备上的数据；只有主动刷新时才连接校园服务。', '读取中'],
    content: ['数据已就绪', '内容来自确定性脱敏快照，结构、来源和更新时间均可独立核验。', '已同步'],
    empty: ['这里还没有内容', '当前范围没有可显示的记录。可以调整范围，或在需要时主动刷新来源。', '调整范围'],
    stale: ['正在显示本地缓存', '网络更新暂不可用；保留最后一次有效内容，并明确显示缓存时间。', '缓存可用'],
    error: ['暂时无法完成', '已有有效内容不会被清空。检查账户或网络后，可以从这里安全重试。', '需要处理'],
  };

  function copyFor(entry, state) {
    if (state === 'loading') {
      return [`正在读取${entry.title}`, `正在从${entry.source}恢复数据；已有页面框架与输入保持可用。`, '读取中'];
    }
    if (state === 'error') {
      return [`${entry.title}暂不可用`, `无法从${entry.source}完成本次操作；${entry.items[0]}仍保持原有状态，可检查条件后重试。`, '需要处理'];
    }
    if (state === 'empty') {
      return [`当前没有${entry.title}内容`, `当前范围没有来自${entry.source}的记录；可调整范围或前往配置。`, '调整范围'];
    }
    if (state === 'initial') {
      return [`尚未读取${entry.title}`, `先确认${entry.source}的访问范围，再由你决定是否开始。`, '尚未开始'];
    }
    return stateCopy[state];
  }

  function navMarkup(active, compact = false) {
    const visible = compact ? navigation.slice(0, 3).concat([['more', '•••', '更多']]) : navigation;
    return visible.map(([id, icon, label]) => {
      const selected = id === active || (compact && id === 'more' && !['home', 'academic', 'schedule'].includes(active));
      return `<button class="reference-nav-item${selected ? ' is-active' : ''}" type="button"${selected ? ' aria-current="page"' : ''}><span aria-hidden="true">${icon}</span><span>${label}</span></button>`;
    }).join('');
  }

  function contentMarkup(entry, state) {
    const [heading, description, status] = copyFor(entry, state);
    const id = entry.id;
    if (state === 'loading') {
      if (id === 'academic.calendar' || id === 'external.pdf' || id === 'external.webview') {
        return `<section class="reference-card reference-document"><div class="reference-document-toolbar"><span>${id === 'external.webview' ? entry.source : '页码加载中'}</span><button type="button">取消</button><button type="button">外部打开</button></div><div class="reference-document-canvas"><span class="reference-spinner" aria-hidden="true"></span><strong>${heading}</strong><span>${description}</span></div></section>`;
      }
      if (id.startsWith('settings.')) {
        return `<section class="reference-card reference-settings-list"><div class="reference-banner">${description}</div>${entry.items.map(item => `<div class="reference-setting-row"><span><strong>${item}</strong><small>保留当前设置</small></span><button type="button" disabled>处理中</button></div>`).join('')}</section>`;
      }
      if (id.startsWith('mail.')) {
        return `<section class="reference-mail"><aside class="reference-card"><h2>收件箱</h2><div class="reference-items">${entry.items.map(item => `<div class="reference-item"><span>${item}</span></div>`).join('')}</div></aside><article class="reference-card reference-loading"><div><span class="reference-spinner" aria-hidden="true"></span><h2>${heading}</h2><p>${description}</p></div></article></section>`;
      }
      return `<section class="reference-card reference-loading" aria-label="正在加载"><div><span class="reference-state-label">${status}</span><h2>${heading}</h2><p>${description}</p><span class="reference-spinner" aria-hidden="true"></span></div></section>`;
    }
    if (state === 'initial' || state === 'empty' || state === 'error') {
      if (state === 'error' && (id === 'academic.calendar' || id === 'external.pdf' || id === 'external.webview')) {
        return `<section class="reference-card reference-document"><div class="reference-document-toolbar"><span>${entry.source}</span><button type="button">重试</button><button type="button">外部打开</button></div><div class="reference-document-canvas"><span class="reference-symbol" aria-hidden="true">!</span><strong>${heading}</strong><span>${description}</span></div></section>`;
      }
      if (state === 'error' && id.startsWith('settings.')) {
        return `<section class="reference-card reference-settings-list"><div class="reference-banner is-error">${description}</div>${entry.items.map((item, index) => `<div class="reference-setting-row"><span><strong>${index === 0 ? '已完成：' : '未完成：'}${item}</strong><small>${index === 0 ? '结果已保留' : '可安全重试'}</small></span><button type="button">${index === 0 ? '查看' : '重试'}</button></div>`).join('')}</section>`;
      }
      const symbol = state === 'error' ? '!' : state === 'empty' ? '○' : '→';
      return `<section class="reference-card reference-empty"><div><span class="reference-symbol" aria-hidden="true">${symbol}</span><span class="reference-state-label">${status}</span><h2>${heading}</h2><p>${description}</p><div class="reference-state-context">${entry.items.map(item => `<span>${item}</span>`).join('')}</div><button type="button">${state === 'error' ? '检查后重试' : state === 'empty' ? '调整范围' : entry.primaryAction}</button></div></section>`;
    }
    const banner = state === 'stale' ? `<div class="reference-banner">当前显示 09:30 的本地缓存；刷新失败不会删除这些内容。</div>` : '';
    const items = entry.items.map((item, index) => `<div class="reference-item"><span class="reference-item-mark" aria-hidden="true"></span><span>${item}</span><span>${index === 0 ? '当前' : index === 1 ? '随后' : '详情'}</span></div>`).join('');
    if (id.startsWith('components.')) {
      return `<section class="reference-component-grid">${entry.items.map((item, index) => `<article class="reference-card reference-component-sample"><span>${index + 1}</span><h2>${item}</h2><button type="button" class="${index === 0 ? 'reference-demo-primary' : ''}">${index === 0 ? '执行行动' : '查看状态'}</button></article>`).join('')}</section>`;
    }
    if (id === 'home.dashboard') {
      return `<article class="reference-card reference-timeline">${banner}<span class="reference-state-label">${status}</span><h2>下一项是数据结构，还有 42 分钟开始</h2>${entry.items.map((item, index) => `<div class="reference-timeline-row"><time>${['10:00', '14:00', '18:30'][index]}</time><i aria-hidden="true"></i><span>${item}</span></div>`).join('')}</article><aside class="reference-aside"><article class="reference-card reference-metric"><span>今日学程</span><strong>3</strong><span>课程与待办</span></article><div class="reference-actions"><button type="button">校园卡</button><button type="button">邮箱</button></div></aside>`;
    }
    if (id.includes('campus-card')) {
      return `<section class="reference-balance"><article class="reference-card reference-balance-hero"><span>校园卡余额</span><strong>¥128.50</strong><small>09:30 本地快照</small></article><article class="reference-card"><h2>最近交易</h2><div class="reference-items">${items}</div></article></section>`;
    }
    if (id === 'schedule.calendar') {
      return `<section class="reference-card reference-schedule">${banner}<div class="reference-week">${['周一', '周二', '周三', '周四', '周五', '周六 · 今天', '周日'].map((day, index) => `<strong class="${index === 5 ? 'is-current' : ''}">${day}</strong>`).join('')}</div><div class="reference-week reference-week-courses"><span>${entry.items[0]}</span><span></span><span>${entry.items[1]}</span><span></span><span>${entry.items[2]}</span><span class="is-current">软件工程实践<br />实训中心 405</span><span></span></div></section>`;
    }
    if (id.startsWith('info.')) {
      return `<section class="reference-feed"><div>${banner}${entry.items.map((item, index) => `<article class="reference-card reference-feed-entry"><span>${index === 0 ? '学校官网' : index === 1 ? '图书馆' : '第二课堂'}</span><h2>${item}</h2><p>7 月 ${18 - index} 日 · 已保存到本机</p></article>`).join('')}</div><aside class="reference-card"><h2>来源筛选</h2><div class="reference-items">${items}</div></aside></section>`;
    }
    if (id === 'mail.inbox' || id === 'mail.message-detail') {
      return `<section class="reference-mail ${id === 'mail.inbox' ? 'is-inbox' : 'is-detail'}"><aside class="reference-card"><h2>收件箱</h2><div class="reference-items">${items}</div></aside><article class="reference-card reference-mail-body"><span class="reference-state-label">只读邮件</span><h2>${entry.items[0]}</h2><p>教学办公室 · 08:42</p><div class="reference-letter">同学你好，课程安排已更新。请核对时间与教室，原始邮件已安全保存在本机。</div></article></section>`;
    }
    if (id === 'mail.compose') {
      return `<section class="reference-card reference-compose"><label>收件人<input value="advisor@example.invalid" /></label><label>主题<input value="课程安排确认" /></label><label>正文<textarea>老师您好，我已核对本学期课程安排，谢谢。</textarea></label><div><button class="reference-demo-primary" type="button">发送邮件</button></div></section>`;
    }
    if (id.startsWith('links.')) {
      return `<section class="reference-directory">${entry.items.map((item, index) => `<article class="reference-card reference-link-card"><span aria-hidden="true">${['锁', '书', '校'][index]}</span><h2>${item}</h2><p>${index === 0 ? '需要现有 OA 登录态' : '将在确认后打开外部目标'}</p><button type="button">查看目标 ↗</button></article>`).join('')}</section>`;
    }
    if (id.startsWith('settings.')) {
      if (id === 'settings.appearance') {
        return `<section class="reference-card reference-settings-list"><div class="reference-segmented" role="radiogroup" aria-label="颜色主题">${entry.items.map((item, index) => `<button type="button" role="radio" aria-checked="${index === 0}" class="${index === 0 ? 'is-selected' : ''}">${item}</button>`).join('')}</div></section>`;
      }
      const usesSwitches = id === 'settings.home-notifications';
      return `<section class="reference-card reference-settings-list">${banner}${entry.items.map((item, index) => `<div class="reference-setting-row"><span><strong>${item}</strong><small>${index === 0 ? '当前设置' : '保存在本机'}</small></span><button type="button"${usesSwitches ? ` role="switch" aria-checked="${index === 0}"` : ''}>${usesSwitches ? (index === 0 ? '已开启' : '关闭') : '打开'}</button></div>`).join('')}</section>`;
    }
    if (id.startsWith('legal.')) {
      return `<article class="reference-card reference-legal">${entry.items.map((item, index) => `<section><h2>${item}</h2><p>${index + 1}. 本节说明该数据与功能的使用边界、保存位置和用户可执行的管理方式。</p></section>`).join('')}</article>`;
    }
    if (id === 'academic.calendar' || id === 'external.pdf' || id === 'external.webview') {
      const documentActions = id === 'external.webview'
        ? '<button type="button">刷新</button><button type="button">外部打开</button>'
        : '<button type="button">缩小</button><button type="button">放大</button><button type="button">外部打开</button>';
      return `<section class="reference-card reference-document"><div class="reference-document-toolbar"><span>${id === 'external.webview' ? 'portal.example.invalid' : '第 1 / 4 页'}</span>${documentActions}</div><div class="reference-document-canvas" data-external-region="document"><strong>${id === 'external.webview' ? '校园门户网页正文' : 'PDF 文档正文'}</strong><span>此外部内容区域由对应平台独立绘制</span></div></section>`;
    }
    if (id === 'external.system-auth') {
      return `<section class="reference-auth-stage"><div class="reference-card reference-system-dialog" data-external-region="system-dialog"><span aria-hidden="true">◎</span><h2>Windows 安全中心</h2><p>验证身份以解锁工大聚合</p><button type="button">使用 PIN</button></div></section>`;
    }
    if (id.includes('grade') || id.includes('exam') || id.includes('report') || id.includes('sports') || id === 'academic.overview') {
      return `<section class="reference-records"><article class="reference-card reference-record-summary"><span>${entry.kicker}</span><strong>${id.includes('grade') ? '3.62' : id.includes('report') ? '85%' : '3'}</strong><small>${entry.source}</small></article><article class="reference-card"><h2>${entry.title}</h2><div class="reference-items">${items}</div></article></section>`;
    }
    if (id.startsWith('shell.') || id.startsWith('consent.') || id.startsWith('security.')) {
      return `<section class="reference-flow">${entry.items.map((item, index) => `<article class="reference-card"><span>${index + 1}</span><h2>${item}</h2><p>${index === 0 ? '当前步骤' : '完成后继续'}</p></article>`).join('')}</section>`;
    }
    return `<article class="reference-card reference-state-hero">${banner}<span class="reference-state-label">${status}</span><h2>${heading}</h2><p>${description}</p><div class="reference-items">${items}</div></article><aside class="reference-aside"><article class="reference-card reference-metric"><span>本机有效数据</span><strong>${state === 'stale' ? '09:30' : entry.items.length}</strong><span>${entry.source}</span></article><div class="reference-actions"><button type="button">查看来源</button><button type="button">更多</button></div></aside>`;
  }

  window.qingyuanStateReference = {
    render(payload) {
      const {entry, group, state, theme} = payload;
      const root = document.querySelector('[data-reference-root]');
      const [groupLabel, groupIcon, domain] = groupMeta[group] || groupMeta.global;
      document.documentElement.dataset.theme = theme;
      root.style.setProperty('--reference-domain', domain);
      document.querySelector('[data-reference-nav]').innerHTML = navMarkup(group);
      document.querySelector('[data-reference-bottom-nav]').innerHTML = navMarkup(group, true);
      document.querySelector('[data-reference-group]').textContent = groupLabel;
      document.querySelector('[data-reference-source]').textContent = entry.source;
      document.querySelector('[data-reference-kicker]').textContent = entry.kicker;
      document.querySelector('[data-reference-title]').textContent = entry.title;
      document.querySelector('[data-reference-summary]').textContent = entry.summary;
      const headingAction = document.querySelector('[data-reference-action]');
      headingAction.textContent = entry.primaryAction;
      headingAction.hidden = entry.id.startsWith('components.') || entry.id === 'mail.compose';
      document.querySelector('[data-reference-source-detail]').textContent = `${groupIcon}  ${entry.source}`;
      document.querySelector('[data-reference-state]').innerHTML = contentMarkup(entry, state);
      document.body.dataset.surface = entry.id;
      document.body.dataset.state = state;
    },
  };
})();
