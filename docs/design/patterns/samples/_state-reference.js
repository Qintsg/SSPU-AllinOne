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

  function navMarkup(active, compact = false) {
    const visible = compact ? navigation.slice(0, 3).concat([['more', '•••', '更多']]) : navigation;
    return visible.map(([id, icon, label]) => {
      const selected = id === active || (compact && id === 'more' && !['home', 'academic', 'schedule'].includes(active));
      return `<button class="reference-nav-item${selected ? ' is-active' : ''}" type="button"${selected ? ' aria-current="page"' : ''}><span aria-hidden="true">${icon}</span><span>${label}</span></button>`;
    }).join('');
  }

  function contentMarkup(entry, state) {
    const [heading, description, status] = stateCopy[state];
    if (state === 'loading') {
      return `<section class="reference-loading" aria-label="正在加载"><article class="reference-skeleton"><i></i><i></i><i></i><span class="reference-spinner" aria-hidden="true"></span></article><article class="reference-skeleton"><i></i><i></i><i></i></article><article class="reference-skeleton"><i></i><i></i><i></i></article></section>`;
    }
    if (state === 'initial' || state === 'empty' || state === 'error') {
      const symbol = state === 'error' ? '!' : state === 'empty' ? '○' : '→';
      return `<section class="reference-card reference-empty"><div><span class="reference-symbol" aria-hidden="true">${symbol}</span><span class="reference-state-label">${status}</span><h2>${heading}</h2><p>${description}</p><button type="button">${state === 'error' ? '检查后重试' : state === 'empty' ? '调整范围' : entry.primaryAction}</button></div></section>`;
    }
    const banner = state === 'stale' ? `<div class="reference-banner">当前显示 09:30 的本地缓存；刷新失败不会删除这些内容。</div>` : '';
    const items = entry.items.map((item, index) => `<div class="reference-item"><span class="reference-item-mark" aria-hidden="true"></span><span>${item}</span><span>${index === 0 ? '当前' : index === 1 ? '随后' : '详情'}</span></div>`).join('');
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
      document.querySelector('[data-reference-action]').textContent = entry.primaryAction;
      document.querySelector('[data-reference-source-detail]').textContent = `${groupIcon}  ${entry.source}`;
      document.querySelector('[data-reference-state]').innerHTML = contentMarkup(entry, state);
      document.body.dataset.surface = entry.id;
      document.body.dataset.state = state;
    },
  };
})();
