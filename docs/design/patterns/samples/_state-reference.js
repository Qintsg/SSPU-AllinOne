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
      return [`正在读取${entry.title}`, entry.stateMessages?.loading || `正在从${entry.source}恢复数据；已有页面框架与输入保持可用。`, '读取中'];
    }
    if (state === 'error') {
      return [`${entry.title}暂不可用`, entry.stateMessages?.error || `无法从${entry.source}完成本次操作；${entry.items[0]}仍保持原有状态，可检查条件后重试。`, '需要处理'];
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

  function aboutRowsMarkup(entry, disabled = false, banner = '') {
    const rows = entry.stateRows?.content;
    return `<section class="reference-card reference-settings-list">${banner}${entry.items.map((item, index) => `<div class="reference-setting-row"><span><strong>${item}</strong><small>${index === 0 ? '当前设置' : '保存在本机'}</small></span><button type="button"${disabled ? ' disabled' : ''}>${rows?.[index]?.action ?? '打开'}</button></div>`).join('')}</section>`;
  }

  const licenseDetails = {
    Flutter: ['跨平台 UI 框架与渲染基础能力', 'BSD-3-Clause'],
    fluentui_system_icons: ['YhIcons 语义图标门面的底层字形资源', 'MIT'],
    shared_preferences: ['本地持久化存储', 'BSD-3-Clause'],
    path_provider: ['平台应用支持目录解析', 'BSD-3-Clause'],
    crypto: ['SHA-256 等哈希算法', 'BSD-3-Clause'],
    flutter_secure_storage: ['系统安全存储凭据保存', 'BSD-3-Clause'],
    local_auth: ['系统 PIN / 生物识别快速验证', 'BSD-3-Clause'],
    url_launcher: ['打开外部链接', 'BSD-3-Clause'],
    open_filex: ['打开本地文件、安装包或所在文件夹', 'BSD-3-Clause'],
    window_manager: ['Flutter 桌面窗口管理', 'MIT'],
    tray_manager: ['系统托盘图标管理', 'MIT'],
    dio: ['强大的 HTTP 客户端库', 'MIT'],
    local_notifier: ['Windows 本地系统通知推送', 'MIT'],
    html: ['HTML 解析库', 'MIT'],
    gbk_codec: ['GBK / GB2312 页面解码', 'MIT'],
    flutter_animate: ['页面入场与微交互动效', 'BSD-3-Clause'],
    flutter_inappwebview: ['内嵌 WebView 与 WebView2 能力', 'Apache-2.0'],
    package_info_plus: ['应用版本与包信息读取', 'BSD-3-Clause'],
    enough_mail: ['学校邮箱 IMAP / POP / SMTP 协议客户端', 'MPL-2.0'],
    pdfrx: ['应用内 PDF 查看与 PDF 渲染能力', 'MIT'],
    pdfrx_engine: ['PDF 文本抽取与底层 PDFium 封装', 'MIT'],
    MiSans: ['小米系统字体，数字等宽', 'MiSans EULA'],
  };

  let modalReturnFocus = null;

  function closeReferenceModal() {
    const scrim = document.querySelector('.reference-modal-scrim');
    if (!scrim || scrim.hidden) return;
    scrim.hidden = true;
    if (modalReturnFocus?.isConnected) modalReturnFocus.focus();
  }

  function prepareReferenceModal(returnFocus) {
    const modal = document.querySelector('[data-reference-modal]');
    if (!modal) return;
    modalReturnFocus = returnFocus;
    const cancel = modal.querySelector('[data-reference-modal-cancel]');
    cancel?.addEventListener('click', closeReferenceModal);
    cancel?.focus();
  }

  document.addEventListener('keydown', event => {
    const modal = document.querySelector('[data-reference-modal]');
    if (!modal || modal.closest('.reference-modal-scrim')?.hidden) return;
    if (event.key === 'Escape') {
      event.preventDefault();
      closeReferenceModal();
      return;
    }
    if (event.key !== 'Tab') return;
    const targets = [...modal.querySelectorAll('button:not([disabled]), [href], [tabindex]:not([tabindex="-1"])')];
    if (!targets.length) return;
    const first = targets[0];
    const last = targets[targets.length - 1];
    if (event.shiftKey && (document.activeElement === first || !modal.contains(document.activeElement))) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && (document.activeElement === last || !modal.contains(document.activeElement))) {
      event.preventDefault();
      first.focus();
    }
  });

  function licenseDescription(license) {
    if (license === 'MIT') return '宽松许可；允许使用、复制、修改与分发，需保留版权和许可声明。';
    if (license === 'Apache-2.0') return '宽松许可；包含专利授权条款，分发时保留许可证与必要 NOTICE。';
    if (license === 'MPL-2.0') return '文件级弱 copyleft；修改 MPL 覆盖文件时提供对应源代码。';
    if (license === 'MiSans EULA') return '字体最终用户许可；随应用使用与分发时遵守小米字体许可条款。';
    return '宽松许可；使用与分发时保留版权声明、许可文本和免责声明。';
  }

  function licenseMarkup(entry, disabled = false) {
    return `<section class="reference-license-list"><div class="reference-license-header"><strong>项目</strong><strong>使用场景</strong><strong>许可证</strong><strong>许可证说明</strong></div>${entry.items.map(item => {
      const [description, license] = licenseDetails[item] || ['应用运行依赖', '请以项目发布的许可证为准'];
      return `<article class="reference-license-entry"><button class="reference-license-link" type="button"${disabled ? ' disabled' : ''}><strong>${item}</strong><span class="reference-license-link-icon" aria-hidden="true">↗</span></button><p class="reference-license-use">${description}</p><small>${license}</small><p class="reference-license-terms">${licenseDescription(license)}</p></article>`;
    }).join('')}</section>`;
  }

  function externalScenarioMarkup(entry, state) {
    const disabled = state === 'operation-locked';
    const base = entry.id === 'settings.licenses'
      ? licenseMarkup(entry, disabled)
      : aboutRowsMarkup(entry, disabled);
    if (state === 'external-error') {
      const banner = `<div class="reference-banner is-error">系统浏览器未能打开${entry.id === 'settings.licenses' ? ' Flutter' : ' GitHub'}；请检查默认浏览器设置后重试。</div>`;
      return entry.id === 'settings.about'
        ? aboutRowsMarkup(entry, false, banner)
        : `${banner}${base}`;
    }
    if (state === 'operation-locked') {
      const banner = entry.id === 'settings.licenses'
        ? '<div class="reference-banner">正在交给系统浏览器；完成前已锁定其它外部链接。</div>'
        : '';
      return `${banner}${base}`;
    }
    if (state === 'external-cancelled') {
      return `${base}<div class="reference-toast"><i aria-hidden="true">ⓘ</i><span><strong>已取消打开${entry.id === 'settings.licenses' ? ' Flutter' : ' GitHub'}</strong><small>${entry.id === 'settings.licenses' ? '许可清单和阅读位置均已保留。' : '仍停留在关于页面。'}</small></span><button type="button" aria-label="关闭反馈">×</button></div>`;
    }
    const target = entry.id === 'settings.licenses' ? 'flutter.dev' : 'github.com/Qintsg/SSPU-AllinOne';
    const titleId = `reference-${entry.id.replace('.', '-')}-external-title`;
    return `${base}<div class="reference-modal-scrim"><section class="reference-card reference-modal" role="dialog" aria-modal="true" aria-labelledby="${titleId}" data-reference-modal><h2 id="${titleId}">打开${entry.id === 'settings.licenses' ? ' Flutter' : ' GitHub 仓库'}</h2><p>即将在系统浏览器打开 ${target}。离开应用后，网页不再受本应用的本地保护。</p><div><button type="button" data-reference-modal-cancel>取消</button><button class="reference-demo-primary" type="button">继续打开</button></div></section></div>`;
  }

  function contentMarkup(entry, state) {
    const id = entry.id;
    if ((id === 'settings.about' || id === 'settings.licenses') && ['external-confirmation', 'external-cancelled', 'external-error', 'operation-locked'].includes(state)) {
      return externalScenarioMarkup(entry, state);
    }
    const [heading, description, status] = copyFor(entry, state);
    if (state === 'loading') {
      if (id === 'academic.calendar' || id === 'external.pdf' || id === 'external.webview') {
        return `<section class="reference-card reference-document"><div class="reference-document-toolbar"><span>${id === 'external.webview' ? entry.source : '页码加载中'}</span><button type="button">取消</button><button type="button">外部打开</button></div><div class="reference-document-canvas"><span class="reference-spinner" aria-hidden="true"></span><strong>${heading}</strong><span>${description}</span></div></section>`;
      }
      if (id.startsWith('settings.')) {
        const rows = entry.stateRows?.loading;
        return `<section class="reference-card reference-settings-list"><div class="reference-banner">${description}</div>${entry.items.map((item, index) => `<div class="reference-setting-row"><span><strong>${rows?.[index]?.label ?? item}</strong><small>保留当前设置</small></span><button type="button" disabled>处理中</button></div>`).join('')}</section>`;
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
        const rows = entry.stateRows?.error;
        return `<section class="reference-card reference-settings-list"><div class="reference-banner is-error">${description}</div>${entry.items.map((item, index) => {
          const row = rows?.[index];
          return `<div class="reference-setting-row"><span><strong>${row?.prefix ?? (index === 0 ? '已完成：' : '未完成：')}${row?.label ?? item}</strong><small>${row?.status ?? (index === 0 ? '结果已保留' : '可安全重试')}</small></span><button type="button">${row?.action ?? (index === 0 ? '查看' : '重试')}</button></div>`;
        }).join('')}</section>`;
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
      if (id === 'settings.about') return aboutRowsMarkup(entry);
      if (id === 'settings.licenses') return licenseMarkup(entry);
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
      headingAction.disabled = state === 'operation-locked';
      document.querySelector('[data-reference-source-detail]').textContent = `${entry.sourceSymbol || groupIcon}  ${entry.source}`;
      document.querySelector('.reference-source-strip time').hidden = entry.sourceTimestamp === false;
      const stateHost = document.querySelector('[data-reference-state]');
      stateHost.innerHTML = contentMarkup(entry, state);
      const externalReturnFocus = entry.id === 'settings.licenses'
        ? stateHost.querySelector('.reference-license-link')
        : document.querySelector('[data-reference-more]');
      if (state === 'external-confirmation') {
        externalReturnFocus?.focus();
        prepareReferenceModal(externalReturnFocus);
      } else if (state === 'external-cancelled' && entry.id === 'settings.about') {
        externalReturnFocus?.focus();
      }
      document.body.dataset.surface = entry.id;
      document.body.dataset.state = state;
    },
  };
})();
