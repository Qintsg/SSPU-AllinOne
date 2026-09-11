/*
 * 清源全状态参考渲染器 — 按视觉清单生成确定性页面状态。
 * @Project : SSPU-AllinOne
 * @File : _state-reference.js
 * @Author : Qintsg
 * @Date : 2026-08-14
 */
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
  const qingyuanDestinations = [
    ['⌂', '主页'],
    ['学', '教务'],
    ['▦', '课表'],
    ['ⓘ', '信息'],
    ['✉', '邮箱'],
    ['↗', '跳转'],
    ['⚙', '设置'],
  ];
  const stateCopy = {
    initial: ['准备好后再开始', '当前还没有读取校园数据。先说明将要访问的来源，再由你决定是否继续。', '开始读取'],
    loading: ['正在读取本地快照', '先恢复已经保存在设备上的数据；只有主动刷新时才连接校园服务。', '读取中'],
    content: ['数据已就绪', '内容来自确定性脱敏快照，结构、来源和更新时间均可独立核验。', '已同步'],
    empty: ['这里还没有内容', '当前范围没有可显示的记录。可以调整范围，或在需要时主动刷新来源。', '调整范围'],
    stale: ['正在显示本地缓存', '网络更新暂不可用；保留最后一次有效内容，并明确显示缓存时间。', '缓存可用'],
    error: ['暂时无法完成', '已有有效内容不会被清空。检查账户或网络后，可以从这里安全重试。', '需要处理'],
  };

  const scenarioCopy = {
    'partial-error': ['部分内容未更新', '部分来源未完成本次读取；已有有效内容和操作位置均已保留，可在原位置重试。', '部分完成'],
    'operation-locked': ['正在处理', '当前操作尚未完成；已锁定重复操作，现有内容与返回路径保持可用。', '处理中'],
    'credentials-required': ['需要账户信息', '当前功能需要先在设置中保存对应账户信息；已有本地内容仍可查看。', '需要配置'],
    'credentials-partial': ['部分账户尚未连接', '部分来源缺少凭据；已连接内容仍可使用，可稍后在设置中补齐。', '部分连接'],
    'validation-error': ['需要检查输入', '当前输入未通过校验；已保留上一次有效结果，可修正后重试。', '需要检查'],
    'external-confirmation': ['确认打开外部内容', '即将离开应用打开外部来源；当前页面和返回路径会保留。', '等待确认'],
    'external-cancelled': ['已取消外部打开', '没有离开应用；当前页面和操作位置已保留，可再次尝试。', '已取消'],
    'external-error': ['外部打开失败', '系统未能打开外部来源；仍停留在应用内，可检查系统设置后重试。', '需要处理'],
  };

  /**
   * 为基础状态和场景状态提供可渲染文案。
   * :param entry: 当前视觉清单条目。
   * :param state: 要渲染的状态标识。
   * :returns: 标题、说明和状态标签。
   */
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
    return stateCopy[state] || scenarioCopy[state] || [
      `${entry.title}状态`,
      `当前处于${state}状态；现有内容与恢复路径保持可用。`,
      '需要处理',
    ];
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
    flutter_local_notifications: ['五端系统通知与本地定时提醒', 'BSD-3-Clause'],
    timezone: ['课程与考试提醒的本地时区计算', 'BSD-3-Clause'],
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

  function webViewSurfaceMarkup(entry, state) {
    const busy = state === 'operation-locked';
    const externalError = state === 'external-error';
    const externalConfirmation = state === 'external-confirmation';
    const loading = state === 'loading';
    const content = state === 'content';
    const banner = busy
      ? '<div class="reference-banner" role="status">正在交给系统浏览器；完成前已锁定重复外部打开，网页和返回路径保持可用。</div>'
      : externalError
      ? '<div class="reference-banner is-error" role="alert">系统浏览器未能打开校园网页；仍停留在应用内，可检查默认浏览器设置后重试。</div>'
      : '';
    const heading = '网页加载失败';
    const description = '无法加载 portal.example.invalid：校园网或 WebView 运行时暂不可用。没有自动离开应用。';
    const retainedContent = content || externalError || busy || externalConfirmation;
    const scoredExternalContent = content || externalError || busy;
    const body = loading
      ? '<main class="reference-webview-document is-external"><span class="reference-spinner" aria-hidden="true"></span><strong>网页正在加载</strong><p>平台 WebView runner 将在此处加载真实网页。</p></main>'
      : retainedContent
      ? `<main class="reference-webview-document is-external"${scoredExternalContent ? ' data-external-region="document"' : ''}><span class="reference-webview-symbol" aria-hidden="true">↗</span><strong>上海第二工业大学校园门户</strong><p>网页正文属于外部区域，由 sidecar 标注责任边界。</p></main>`
      : `<main class="reference-webview-document"><svg class="reference-webview-warning" aria-hidden="true" viewBox="0 0 48 48"><path d="M24 6 43 40H5Z"/><path d="M24 17v12"/><circle cx="24" cy="35" r="1"/></svg><strong>${heading}</strong><p>${description}</p><div class="reference-webview-actions"><button class="reference-demo-primary" type="button"${busy ? ' disabled' : ''}>重新加载</button><button type="button"${busy ? ' disabled' : ''}>${busy ? '正在外部打开…' : '在浏览器中打开'}</button></div></main>`;
    const progress = loading ? '<div class="reference-webview-progress" aria-hidden="true"><i></i></div>' : '';
    const confirmation = externalConfirmation
      ? '<div class="reference-modal-scrim"><section class="reference-card reference-modal" role="dialog" aria-modal="true" aria-labelledby="reference-webview-external-title" data-reference-modal><h2 id="reference-webview-external-title">在系统浏览器中打开？</h2><p>即将在系统浏览器打开 portal.example.invalid。离开应用后，网页不再受本应用的本地保护。</p><div><button type="button" data-reference-modal-cancel>取消</button><button class="reference-demo-primary" type="button">继续打开</button></div></section></div>'
      : '';
    return `<section class="reference-webview-stage"><header class="reference-webview-toolbar"><button class="reference-webview-back" type="button" aria-label="返回">←</button><strong>${loading ? '正在打开校园门户' : '校园门户'}</strong><button type="button" aria-label="刷新"${busy ? ' disabled' : ''}>↻</button><button type="button" aria-label="在浏览器中打开"${busy ? ' disabled' : ''}>↗</button></header>${banner}${progress}${body}${confirmation}</section>`;
  }

  function calendarSurfaceMarkup(entry, state) {
    const loading = state === 'loading';
    const empty = state === 'empty';
    const error = state === 'error';
    const stale = state === 'stale';
    const partialError = state === 'partial-error';
    const busy = state === 'operation-locked';
    const externalError = state === 'external-error';
    const externalConfirmation = state === 'external-confirmation';
    const retained = !loading && !empty && !error;
    const scoredDocument = ['content', 'stale', 'partial-error', 'operation-locked', 'external-error'].includes(state);
    const banner = busy
      ? '<div class="reference-calendar-banner" role="status">正在刷新公开校历；当前学年、PDF 和返回路径保持可用，完成前已锁定其它远端操作。</div>'
      : partialError
      ? '<div class="reference-calendar-banner is-error" role="alert">公开校历刷新未完成；当前仍显示 7 月 17 日保存的有效档案，可在原位置重试。</div>'
      : externalError
      ? '<div class="reference-calendar-banner is-error" role="alert">系统未能打开教务处校历 PDF；仍停留在当前学年，可检查默认 PDF 应用后重试。</div>'
      : stale
      ? '<div class="reference-calendar-banner is-warn" role="status">当前显示 7 月 17 日保存的公开校历；原始 PDF 与学年选择仍可使用。</div>'
      : '';
    const appbar = `<header class="reference-calendar-appbar"><button type="button" aria-label="返回">←</button><strong>校历</strong><button type="button" aria-label="刷新校历"${loading || busy ? ' disabled' : ''}>↻</button><button type="button" aria-label="外部打开校历 PDF" data-reference-external-trigger${!retained || busy ? ' disabled' : ''}>↗</button></header>`;
    if (!retained) {
      const symbol = loading ? '<span class="reference-spinner" aria-hidden="true"></span>' : `<span class="reference-calendar-state-symbol" aria-hidden="true">${error ? '!' : '○'}</span>`;
      const title = loading ? '正在恢复公开校历' : error ? '暂时无法读取公开校历' : '尚未找到可查看的校历';
      const message = loading
        ? '先读取本机档案；需要时再访问无需登录的教务处公开页面。'
        : error
        ? '本机没有有效档案，教务处公开页面也未完成读取；可在这里重试。'
        : '读取已完成，但 2021 年以后没有可用 PDF；可刷新公开来源。';
      return `<section class="reference-calendar-stage">${appbar}<main class="reference-calendar-state-panel">${symbol}<h1>${title}</h1><p>${message}</p>${loading ? '' : `<button type="button">${error ? '重新读取公开校历' : '刷新公开校历'}</button>`}</main></section>`;
    }
    const confirmation = externalConfirmation
      ? '<div class="reference-modal-scrim"><section class="reference-card reference-modal" role="dialog" aria-modal="true" aria-labelledby="reference-calendar-external-title" data-reference-modal><p class="reference-eyebrow">外部 PDF</p><h2 id="reference-calendar-external-title">在外部应用打开校历？</h2><p>即将打开 jwc.sspu.edu.cn/calendar.pdf。离开应用后，文档不再受本应用的本地保护。</p><div><button type="button" data-reference-modal-cancel>取消</button><button class="reference-demo-primary" type="button">继续打开</button></div></section></div>'
      : '';
    const documentAttribute = scoredDocument ? ' data-external-region="document"' : '';
    const term = `<section class="reference-calendar-term"><small>统一查询学期</small><div class="reference-calendar-term-controls"><label class="reference-calendar-term-control">学年<span><em>2025–26 学年</em><b aria-hidden="true">›</b></span></label><label class="reference-calendar-term-control">学期<span><em>秋季学期</em><b aria-hidden="true">›</b></span></label></div><div class="reference-calendar-term-context"><span>当前实际：2025-2026 学年夏季学期 暑假</span><span>当前日期</span><span>查询使用：2025-2026 学年秋季学期</span></div></section>`;
    return `<section class="reference-calendar-stage">${appbar}<main class="reference-calendar-body">${banner}<div class="reference-calendar-layout"><aside class="reference-calendar-index"><div class="reference-calendar-source"><i aria-hidden="true"></i><span><strong>教务处公开校历</strong><small>无需登录 · 09:30 更新</small></span></div>${term}<nav class="reference-calendar-years" aria-label="学年档案"><button class="is-selected" type="button"${busy ? ' disabled' : ''}><span>2025–2026 学年</span><small>2025-04-24</small></button><button type="button"${busy ? ' disabled' : ''}><span>2024–2025 学年</span><small>2024-04-26</small></button></nav><section class="reference-calendar-evidence"><small>学期边界</small><strong>2025–2026 学年</strong><dl><div><dt>秋季</dt><dd>09.22—01.18</dd></div><div><dt>春季</dt><dd>03.02—06.28</dd></div><div><dt>夏季</dt><dd>5 个教学周</dd></div></dl><p>校运会 11 月 7 日停课；节假日安排以学校后续通知为准</p></section></aside><section class="reference-calendar-document"><header><span><small>原始证据</small><strong>2025–2026 学年校历 PDF</strong></span><button type="button"${busy ? ' disabled' : ''}>专注查看</button></header><div class="reference-calendar-paper"${documentAttribute}><span aria-hidden="true">▤</span><strong>2025–2026 学年校历正文</strong><p>PDF 正文由平台查看器绘制，应用只负责来源、选择与恢复操作。</p></div></section></div></main>${confirmation}</section>`;
  }

  function pdfSurfaceMarkup(entry, state) {
    const loading = state === 'loading';
    const empty = state === 'empty';
    const error = state === 'error';
    const partialError = state === 'partial-error';
    const busy = state === 'operation-locked';
    const externalError = state === 'external-error';
    const externalConfirmation = state === 'external-confirmation';
    const retained = ['content', 'partial-error', 'operation-locked', 'external-error', 'external-confirmation'].includes(state);
    const scoredDocument = ['content', 'partial-error', 'operation-locked', 'external-error'].includes(state);
    const banner = busy
      ? '<div class="reference-pdf-banner" role="status">正在下载校历 PDF；当前页码、缩放和正文保持可用，完成前已锁定重复操作。</div>'
      : partialError
      ? '<div class="reference-pdf-banner is-error" role="alert">校历 PDF 未能保存到下载目录；正文和第 1 / 4 页位置已保留，可检查权限后重试。</div>'
      : externalError
      ? '<div class="reference-pdf-banner is-error" role="alert">系统未能打开校历 PDF；仍停留在第 1 / 4 页，可检查默认 PDF 应用后重试。</div>'
      : '';
    const appbar = `<header class="reference-pdf-appbar"><button type="button" aria-label="返回">←</button><strong>2025–2026 学年校历</strong><button type="button" aria-label="下载校历 PDF"${loading || empty || error || busy ? ' disabled' : ''}>↓</button><button type="button" aria-label="外部打开校历 PDF" data-reference-external-trigger${loading || empty || busy ? ' disabled' : ''}>↗</button></header>`;
    const toolbar = `<div class="reference-pdf-toolbar"><span>${retained ? '第 1 / 4 页' : '页码加载中'}</span><button type="button" aria-label="缩小 PDF"${!retained || busy ? ' disabled' : ''}>−</button><button type="button" aria-label="放大 PDF"${!retained || busy ? ' disabled' : ''}>＋</button></div>`;
    let document;
    if (retained) {
      document = `<main class="reference-pdf-document is-external"${scoredDocument ? ' data-external-region="document"' : ''}><span aria-hidden="true">▤</span><strong>2025–2026 学年校历正文</strong><p>PDF 正文属于外部区域，由 sidecar 标注责任边界。</p></main>`;
    } else {
      const symbol = loading ? '<span class="reference-spinner" aria-hidden="true"></span>' : `<span class="reference-calendar-state-symbol" aria-hidden="true">${error ? '△' : '▤'}</span>`;
      const title = loading ? '正在加载校历 PDF' : error ? 'PDF 加载失败' : '暂无可查看的 PDF';
      const message = loading
        ? '正在准备页面与字体；返回操作始终可用。'
        : error
        ? '文件来源：jwc.sspu.edu.cn/calendar.pdf。可重试读取或改用外部应用打开。'
        : '当前校历没有本地文件或可用网络地址；请返回校历档案重新选择。';
      document = `<main class="reference-pdf-document">${symbol}<strong>${title}</strong><p>${message}</p>${loading ? '' : `<div><button type="button">${error ? '重试读取' : '返回校历'}</button>${error ? '<button type="button" data-reference-external-trigger>外部打开</button>' : ''}</div>`}</main>`;
    }
    const confirmation = externalConfirmation
      ? '<div class="reference-modal-scrim"><section class="reference-card reference-modal" role="dialog" aria-modal="true" aria-labelledby="reference-pdf-external-title" data-reference-modal><p class="reference-eyebrow">外部 PDF</p><h2 id="reference-pdf-external-title">在外部应用打开校历？</h2><p>即将打开 jwc.sspu.edu.cn/calendar.pdf。外部应用中的文档不再受本应用本地保护。</p><div><button type="button" data-reference-modal-cancel>取消</button><button class="reference-demo-primary" type="button">继续打开</button></div></section></div>'
      : '';
    return `<section class="reference-pdf-stage">${appbar}${banner}${toolbar}${document}${confirmation}</section>`;
  }

  function academicDetailStateMarkup(entry, state, accent) {
    const loading = state === 'loading';
    const empty = state === 'empty';
    const error = state === 'error';
    const busy = state === 'operation-locked';
    const stale = state === 'stale';
    const action = entry.id === 'academic.student-report' ? '刷新成绩单' : '刷新考勤';
    const source = entry.id === 'academic.student-report' ? '第二课堂 · 本地快照' : '体育系统 · 本地快照';
    const appBarSource = entry.id === 'academic.student-report' ? '第二课堂 · 08:42' : '体育系统 · 08:42';
    const banner = busy
      ? `<div class="reference-academic-banner" role="status">正在${action}；当前内容和返回路径保持可用，完成前已锁定重复刷新。</div>`
      : stale
      ? '<div class="reference-academic-banner is-warn" role="status">正在显示昨日缓存；刷新失败不会删除以下完成度与证据记录。</div>'
      : '';
    let body;
    if (loading || empty || error) {
      const symbol = loading ? '<span class="reference-spinner" aria-hidden="true"></span>' : `<span class="reference-academic-state-symbol" aria-hidden="true">${error ? '!' : '○'}</span>`;
      const title = loading
        ? `正在读取${entry.title}`
        : error
        ? `${entry.title}暂不可用`
        : `当前没有${entry.title}记录`;
      const message = loading
        ? `正在从${source}恢复数据；页面来源和返回路径保持可用。`
        : error
        ? `无法完成本次读取；检查账户或网络后可在本页重试，已有有效缓存不会被清空。`
        : `当前范围没有可展示的记录；可返回教务中心确认学期与账户后再次刷新。`;
      body = `<section class="reference-academic-state-panel">${symbol}<h2>${title}</h2><p>${message}</p>${loading ? '' : '<button type="button">返回教务中心</button>'}</section>`;
    } else {
      body = entry.id === 'academic.student-report'
        ? studentReportLedgerMarkup()
        : sportsAttendanceLedgerMarkup();
    }
    return `<section class="reference-academic-task" style="--academic-accent:${accent}"><header class="reference-academic-appbar"><button type="button" aria-label="返回">←</button><span><small>${entry.kicker}</small><strong>${appBarSource}</strong></span><button type="button" aria-label="更多操作">•••</button></header><main class="reference-academic-scroll"><div class="reference-academic-content"><section class="reference-academic-heading"><div><small>${entry.kicker}</small><h1>${entry.title}</h1><p>${entry.summary}</p></div><button type="button"${loading || busy ? ' disabled' : ''}>${busy ? '正在刷新…' : action}</button></section><div class="reference-academic-source"><i aria-hidden="true"></i><span>学　${source}</span><time>2026-07-18 · 08:42</time></div>${banner}${body}</div></main></section>`;
  }

  function academicEamsFilterMarkup(entry, disabled) {
    const field = (label, value) => `<label><small>${label}</small><button class="reference-academic-filter-trigger" type="button" aria-label="${label}：${value}" aria-haspopup="listbox" aria-expanded="false"${disabled ? ' disabled' : ''}><span>${value}</span><b aria-hidden="true">⌄</b></button></label>`;
    if (entry.id === 'academic.grade-detail') {
      return `<section class="reference-academic-filter${disabled ? ' is-disabled' : ''}" aria-label="成绩范围">${field('学年学期', '全部学期')}<button type="button"${disabled ? ' disabled' : ''}>过程化成绩</button></section>`;
    }
    if (entry.id === 'academic.exam-detail') {
      return `<section class="reference-academic-filter is-exam${disabled ? ' is-disabled' : ''}" aria-label="考试范围">${field('学年', '2025–2026 学年')}${field('学期', '春季学期')}${field('考试类型', '期末考试')}</section>`;
    }
    return `<section class="reference-academic-filter${disabled ? ' is-disabled' : ''}" aria-label="过程化成绩范围">${field('学年学期', '2025–2026 学年春季学期')}</section>`;
  }

  function academicEamsGradeLedgerMarkup() {
    const metrics = [['4.0', '当前 GPA'], ['11', '已获学分'], ['3 门', '课程成绩']];
    const records = [
      ['数据结构', '2025–2026 第 2 学期 · 4 学分', '绩点 4.2', '92', '总评'],
      ['软件工程实践', '2025–2026 第 2 学期 · 2 学分', '绩点 4.5', '优秀', '总评'],
      ['高等数学', '2025–2026 第 1 学期 · 5 学分', '绩点 3.8', '88', '总评'],
    ];
    return `<div class="reference-academic-ledger is-eams"><section class="reference-academic-summary"><div class="reference-academic-metrics is-three">${metrics.map(([value, label]) => `<span><strong>${value}</strong><small>${label}</small></span>`).join('')}</div></section><section class="reference-academic-records"><header><div><small>原始成绩证据</small><h2>课程成绩</h2></div><span>3 门课程</span></header><div>${records.map(([title, meta, detail, value, status]) => `<article><span class="reference-academic-record-mark" aria-hidden="true"></span><div><strong>${title}</strong><small>${meta}</small><p>${detail}</p></div><span><strong>${value}</strong><small>${status}</small></span></article>`).join('')}</div></section></div>`;
  }

  function academicEamsExamLedgerMarkup(disabled) {
    const metrics = [['2', '考试课程'], ['1', '已经排期'], ['1', '等待公布']];
    const records = [
      ['07·22', '09:00–10:30', '数据结构', '教学楼 2 号楼 · 302', '期末考试 · 正常', '已排期', 'CS201'],
      ['待定', '时间待公布', '软件工程实践', '地点待公布', '课程设计答辩安排另行通知', '待公布', 'SE202'],
    ];
    return `<div class="reference-academic-ledger is-eams"><section class="reference-academic-summary"><div class="reference-academic-metrics is-three">${metrics.map(([value, label]) => `<span><strong>${value}</strong><small>${label}</small></span>`).join('')}</div></section><section class="reference-academic-records"><header><div><small>连续时间正序</small><h2>考试时间轴</h2></div><div class="reference-academic-record-meta"><span>期末考试</span><div class="reference-academic-sort" role="radiogroup" aria-label="考试时间顺序"><button type="button" role="radio" aria-checked="true"${disabled ? ' disabled' : ''}>正序</button><button type="button" role="radio" aria-checked="false"${disabled ? ' disabled' : ''}>倒序</button></div></div></header><div>${records.map(([date, time, title, place, detail, status, code]) => `<article><time><strong>${date}</strong><small>${time}</small></time><div><strong>${title}</strong><small>${place}</small><p>${detail}</p></div><span><strong>${status}</strong><small>${code}</small></span></article>`).join('')}</div></section></div>`;
  }

  function academicEamsProcessLedgerMarkup() {
    const chips = [['课堂表现', '95 / 10%'], ['课程作业', '90 / 30%'], ['期中测验', '88 / 20%']];
    return `<div class="reference-academic-ledger is-eams"><section class="reference-academic-summary"><div class="reference-academic-metrics is-three"><span><strong>1</strong><small>有记录课程</small></span><span><strong>3</strong><small>评价证据</small></span><span><strong>4</strong><small>课程学分</small></span></div></section><section class="reference-academic-records reference-academic-process-records"><header><div><small>课程内原始评价</small><h2>过程证据</h2></div><span>2025–2026 第 2 学期</span></header><article><span class="reference-academic-record-mark" aria-hidden="true"></span><div><strong>数据结构</strong><small>专业基础课 · 4 学分</small><div class="reference-academic-evidence-chips">${chips.map(([label, value]) => `<span><small>${label}</small><strong>${value}</strong></span>`).join('')}</div></div></article></section></div>`;
  }

  function academicEamsSurfaceMarkup(entry, state) {
    const loading = state === 'loading';
    const empty = state === 'empty';
    const error = state === 'error';
    const stale = state === 'stale';
    const busy = state === 'operation-locked';
    const action = entry.primaryAction;
    const source = entry.source.replace(' · 09:30', ' · 本地快照');
    const appBarSource = entry.source.replace('本地快照', '09:30');
    const banner = busy
      ? `<div class="reference-academic-banner" role="status">正在${action}；当前筛选范围和有效记录保持可用，完成前已锁定重复请求与范围切换。</div>`
      : stale
      ? '<div class="reference-academic-banner is-warn" role="status">正在显示 07-17 18:00 缓存；刷新失败不会删除当前筛选范围与以下原始记录。</div>'
      : '';
    let body;
    if (loading || empty || error) {
      const symbol = loading ? '<span class="reference-spinner" aria-hidden="true"></span>' : `<span class="reference-academic-state-symbol" aria-hidden="true">${error ? '!' : '○'}</span>`;
      const noun = entry.id === 'academic.exam-detail' ? '考试安排' : entry.id === 'academic.grade-process' ? '过程化成绩' : '课程成绩';
      const title = loading ? `正在读取${noun}` : error ? `${noun}暂不可用` : `当前没有${noun}记录`;
      const message = loading
        ? `正在从${source}恢复数据；筛选范围、页面来源和返回路径保持可见。`
        : error
        ? '暂时无法读取教务数据：请检查校园网络或 VPN 后重试；已有本地数据不会被删除。'
        : '当前筛选范围没有可展示的原始记录；可调整学期或稍后在原位置重新读取。';
      body = `<section class="reference-academic-state-panel">${symbol}<h2>${title}</h2><p>${message}</p>${loading ? '' : `<button type="button">${error ? '检查后重试' : '重新读取'}</button>`}</section>`;
    } else {
      body = entry.id === 'academic.grade-detail'
        ? academicEamsGradeLedgerMarkup()
        : entry.id === 'academic.exam-detail'
        ? academicEamsExamLedgerMarkup(busy)
        : academicEamsProcessLedgerMarkup();
    }
    return `<section class="reference-academic-task" style="--academic-accent:var(--service-academic)"><header class="reference-academic-appbar"><button type="button" aria-label="返回">←</button><span><small>${entry.kicker}</small><strong>${appBarSource}</strong></span><button type="button" aria-label="更多操作">•••</button></header><main class="reference-academic-scroll"><div class="reference-academic-content"><section class="reference-academic-heading"><div><small>${entry.kicker}</small><h1>${entry.title}</h1><p>${entry.summary}</p></div><button type="button"${loading || busy ? ' disabled' : ''}>${busy ? '正在刷新…' : action}</button></section><div class="reference-academic-source"><i aria-hidden="true"></i><span>学　${source}</span><time>${stale ? '2026-07-17 · 18:00' : '2026-07-18 · 09:30'}</time></div>${banner}${academicEamsFilterMarkup(entry, loading || busy)}${body}</div></main></section>`;
  }

  function studentReportLedgerMarkup() {
    const categories = [
      ['社会实践', '2.00 / 2.00', 'is-success'],
      ['创新创业活动', '1.50 / 1.00', 'is-success'],
      ['报告与讲座', '0.50 / 1.00', 'is-progress'],
      ['校园文化活动', '—', 'is-muted'],
    ];
    const records = [
      ['社区数字助老志愿服务', '社会实践 · 志愿服务', '累计 20 小时', '+2.0', '已认定'],
      ['校园应用创新训练', '创新创业 · 创新训练项目', '校级 · 已结项', '+1.5', '通过'],
    ];
    return `<div class="reference-academic-ledger"><section class="reference-academic-summary"><div class="reference-academic-metrics"><span><strong>8.5</strong><small>总已获分数</small></span><span><strong>10</strong><small>总必修积分</small></span><span><strong>进行中</strong><small>总体通过情况</small></span><span><strong>2 项</strong><small>证据记录</small></span></div><div class="reference-academic-categories">${categories.map(([label, value, kind]) => `<span class="${kind}"><small>${label}</small><strong>${value}</strong></span>`).join('')}</div></section><section class="reference-academic-records"><header><div><small>积分证据</small><h2>已获积分记录</h2></div><button type="button">查看积分规则</button></header><div>${records.map(([title, meta, detail, value, status]) => `<article><span class="reference-academic-record-mark" aria-hidden="true"></span><div><strong>${title}</strong><small>${meta}</small><p>${detail}</p></div><span><strong>${value}</strong><small>${status}</small></span></article>`).join('')}</div></section></div>`;
  }

  function sportsAttendanceLedgerMarkup() {
    const metrics = [
      ['12', '总次数'],
      ['6', '晨跑次数'],
      ['6', '课外活动'],
      ['0', '体育长廊'],
      ['0', '次数调整'],
    ];
    const records = [
      ['07·15', '06:45', '晨跑', '学校操场', '有效', '1 次'],
      ['07·17', '18:30', '羽毛球活动', '体育馆 2 号场', '已签到', '1 次'],
    ];
    return `<div class="reference-academic-ledger"><section class="reference-academic-summary is-sports"><div class="reference-academic-metrics">${metrics.map(([value, label]) => `<span><strong>${value}</strong><small>${label}</small></span>`).join('')}</div></section><section class="reference-academic-records"><header><div><small>本学期运动证据</small><h2>考勤明细</h2></div><span>2 条记录</span></header><div>${records.map(([date, time, project, place, status, count]) => `<article><time><strong>${date}</strong><small>${time}</small></time><div><strong>${project}</strong><small>${place}</small><p>${status}</p></div><span><strong>${count}</strong><small>原始记录已保留</small></span></article>`).join('')}</div></section></div>`;
  }

  function scheduleNavigationMarkup() {
    const desktop = qingyuanDestinations.map(([icon, label]) => `<button class="reference-shell-destination${label === '课表' ? ' is-active' : ''}" type="button"${label === '课表' ? ' aria-current="page"' : ''}><span aria-hidden="true">${icon}</span><strong>${label}</strong></button>`).join('');
    const bottom = qingyuanDestinations.slice(0, 4).concat([['•••', '更多']]).map(([icon, label]) => `<button class="reference-shell-destination${label === '课表' ? ' is-active' : ''}" type="button"${label === '课表' ? ' aria-current="page"' : ''}><span aria-hidden="true">${icon}</span><strong>${label}</strong></button>`).join('');
    return {desktop, bottom};
  }

  function scheduleLedgerMarkup(banner = '') {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    const periods = [
      ['1–2', '08:00', [['数据结构', '计算机楼 301', 1]]],
      ['3–4', '09:50', [['软件工程实践', '实训中心 405', 6]]],
      ['5–6', '11:25', [['人机交互设计', '艺术楼 B204', 3]]],
    ];
    const header = `<div class="reference-schedule-week-header"><strong>节次</strong>${weekdays.map((day, index) => `<strong class="${index === 5 ? 'is-current' : ''}">${day}${index === 5 ? ' · 今天' : ''}</strong>`).join('')}</div>`;
    const rows = periods.map(([period, time, courses]) => `<div class="reference-schedule-week-row"><span><strong>${period}</strong><small>${time}</small></span>${weekdays.map((_, index) => {
      const course = courses.find(item => item[2] === index + 1);
      return `<span class="${index === 5 ? 'is-current' : ''}">${course ? `<b>${course[0]}</b><small>${course[1]}</small>` : ''}</span>`;
    }).join('')}</div>`).join('');
    return `${banner}<div class="reference-schedule-tabs">${weekdays.map((day, index) => `<strong class="${index === 5 ? 'is-current' : ''}">${day}${index === 5 ? ' · 今天' : ''}</strong>`).join('')}</div><section class="reference-schedule-mobile-course"><time><strong>09:50 · 3–4 节</strong></time><div><strong>软件工程实践</strong><small>实训中心 405</small></div></section><section class="reference-schedule-week-grid">${header}${rows}</section>`;
  }

  function scheduleStatePanelMarkup(state) {
    const loading = state === 'loading';
    const error = state === 'error';
    const empty = state === 'empty';
    const symbol = loading ? '<span class="reference-spinner" aria-hidden="true"></span>' : `<span class="reference-schedule-state-symbol" aria-hidden="true">${error ? '!' : empty ? '○' : '→'}</span>`;
    const title = loading ? '正在读取当前学期课表' : error ? '课表暂不可用' : empty ? '本学期暂无课程' : '准备读取课程表';
    const message = loading
      ? '正在从教务课表恢复数据；页面、校历入口和返回路径保持可用。'
      : error
      ? '无法完成本次读取；检查 OA 登录或校园网络后可在原位置重试。'
      : empty
      ? '当前学期没有可展示的课程；刚完成选课时可稍后刷新，或查看校历确认学期。'
      : '首次读取只访问当前 OA 登录态下的课表；由你决定何时开始。';
    const context = error ? '已有缓存不会被清空' : empty ? '0 门课程 · 09:30 更新' : '只读访问 · 当前学期';
    return `<section class="reference-schedule-state-panel">${symbol}<small>${loading ? '读取中' : error ? '需要处理' : empty ? '当前范围' : '尚未开始'}</small><h2>${title}</h2><p>${message}</p><span>${context}</span>${loading ? '' : `<div><button type="button">查看校历</button><button class="reference-demo-primary" type="button">${error ? '检查后重试' : empty ? '重新读取' : '开始读取'}</button></div>`}</section>`;
  }

  function scheduleSurfaceMarkup(entry, state) {
    const {desktop, bottom} = scheduleNavigationMarkup();
    const busy = state === 'operation-locked';
    const stale = state === 'stale';
    const content = state === 'content' || stale || busy;
    const loading = state === 'loading';
    const metadata = content || state === 'empty'
      ? `<div class="reference-schedule-meta"><span>● ${state === 'empty' ? '0' : '3'} 门课程</span><span>● ${stale ? '昨日 18:00' : '09:30'} 更新</span>${stale ? '<span class="is-warn">● 本地缓存</span>' : ''}</div>`
      : '';
    const banner = busy
      ? '<div class="reference-schedule-banner" role="status">正在刷新课表；当前课程、星期选择和校历入口保持可用，完成前已锁定重复刷新。</div>'
      : stale
      ? '<div class="reference-schedule-banner is-warn" role="status">正在显示昨日缓存；刷新失败不会删除当前周视图，可在原位置重试。</div>'
      : '';
    const body = content ? scheduleLedgerMarkup(banner) : scheduleStatePanelMarkup(state);
    const actionLabel = busy ? '正在刷新…' : loading ? '正在读取…' : '刷新课表';
    return `<section class="reference-qingyuan-shell reference-schedule-stage"><aside class="reference-shell-rail"><div class="reference-shell-brand" aria-label="工大聚合">工</div><nav>${desktop}</nav></aside><main><div class="reference-schedule-scroll"><div class="reference-schedule-content"><header class="reference-schedule-heading"><div><small>2025–2026 第 2 学期</small><h1>课程表</h1><p>周视图在桌面保持七天空间关系，窄屏切换为按天列表；课程颜色只表达课表业务域。</p></div><div><button type="button">查看校历</button><button class="reference-demo-primary" type="button"${busy || loading ? ' disabled' : ''}>${actionLabel}</button></div></header>${metadata}<main>${body}</main></div></div><nav class="reference-shell-bottom">${bottom}</nav></main></section>`;
  }

  function lockSurfaceMarkup(state, includeExternalDialog = false) {
    const loading = state === 'loading';
    const error = state === 'error';
    const errorText = error ? '<p class="reference-lock-error" role="status">密码错误，请重试</p>' : '';
    const lock = `<section class="reference-global-stage reference-lock-stage"><main class="reference-lock-panel"><div class="reference-security-mark" aria-hidden="true">源</div><p class="reference-eyebrow">本机安全</p><h1>工大聚合</h1><p>应用已锁定，解锁信息只在本机验证。</p><label class="reference-lock-field"><span>密码</span><span class="reference-input${error ? ' is-error' : ''}${loading ? ' is-disabled' : ''}">🔒 <b>${loading ? '••••••••' : '输入密码以解锁'}</b></span></label>${errorText}<button class="reference-lock-action" type="button"${loading ? ' disabled' : ''}>${loading ? '正在验证…' : '解锁'}</button><small>系统认证取消或不可用时，仍可使用本地密码。</small></main></section>`;
    if (!includeExternalDialog) return lock;
    const dialogTitle = state === 'initial' ? '准备系统认证' : state === 'error' ? '系统认证未完成' : '验证身份以解锁工大聚合';
    const dialogMessage = state === 'initial' ? '系统即将请求设备 PIN 或生物识别。' : state === 'error' ? '可重试系统认证，或返回应用输入本地密码。' : '此区域由操作系统绘制，认证信息不会离开设备。';
    return `${lock}<div class="reference-auth-scrim"></div><section class="reference-system-auth-dialog" data-external-region="system-dialog"><span aria-hidden="true">${state === 'error' ? '!' : '◎'}</span><h2>${dialogTitle}</h2><p>${dialogMessage}</p><div><button type="button">返回密码</button><button class="reference-demo-primary" type="button">${state === 'error' ? '重试认证' : '继续'}</button></div></section>`;
  }

  function consentSurfaceMarkup(state) {
    const loading = state === 'initial';
    const error = state === 'error';
    const busy = state === 'operation-locked';
    const persistenceError = state === 'partial-error';
    const document = loading
      ? '<div class="reference-consent-document is-loading" role="status"><span class="reference-spinner" aria-hidden="true"></span><strong>正在加载协议正文</strong><p>正文完整读取后才可继续。</p></div>'
      : error
      ? '<div class="reference-consent-document is-error" role="alert"><strong>无法加载协议正文</strong><p>本地协议文件未就绪；当前不会记录同意，可在这里重试。</p><button type="button">↻　重试加载协议</button></div>'
      : '<div class="reference-consent-document"><h2>工大聚合法律与隐私说明</h2><h3>一、独立工具，不代表学校官方</h3><h3>二、仅供本人校园学习与生活使用</h3><h3>三、凭据与缓存只保存在本机</h3><h3>四、第三方能力遵循各自许可</h3></div>';
    const operationFeedback = busy
      ? '<div class="reference-banner" role="status">正在将协议选择安全保存到本机，完成前请保持应用开启。</div>'
      : persistenceError
      ? '<div class="reference-banner is-error" role="alert">未能保存协议选择；当前不会视为已同意。请检查本机存储后重试，或退出应用。</div>'
      : '';
    return `<section class="reference-global-stage reference-consent-stage"><article class="reference-consent-panel" role="dialog" aria-modal="true" aria-labelledby="reference-consent-title"><header><p class="reference-eyebrow">首次使用</p><h1 id="reference-consent-title">法律与隐私说明</h1><p>请完整阅读。一次同意将同时确认免责声明、用户协议、隐私协议与第三方协议。</p></header>${document}${operationFeedback}<p class="reference-consent-note">${loading || error ? '协议正文加载完成后才可继续。' : '同意后仍可在设置中查看协议并清除本地数据。'}</p><div class="reference-consent-actions"><button type="button"${busy ? ' disabled' : ''}>不同意并退出</button><button class="reference-demo-primary" type="button"${loading || error || busy ? ' disabled' : ''}>${busy ? '正在保存…' : persistenceError ? '重试保存并继续' : '同意全部协议并继续'}</button></div></article></section>`;
  }

  function closeConfirmationMarkup(state) {
    const busy = state === 'operation-locked';
    const error = state === 'error';
    const banner = busy ? '<div class="reference-banner" role="status">正在保存关闭选择并处理窗口，完成前已锁定重复操作。</div>' : error ? '<div class="reference-banner is-error" role="alert">未能完成窗口操作；当前页面和选择仍已保留，可重试或取消。</div>' : '';
    return `${qingyuanShellMarkup('主页')}<div class="reference-close-scrim"></div><section class="reference-close-dialog" role="dialog" aria-modal="true" aria-labelledby="reference-close-title"><p class="reference-eyebrow">桌面窗口</p><h2 id="reference-close-title">关闭工大聚合？</h2><p>最小化会保留当前页面与后台刷新；退出会停止本机任务。</p>${banner}<label class="reference-remember"><span aria-hidden="true">☐</span><span>以后都使用本次选择</span></label><div class="reference-close-actions"><button type="button"${busy ? ' disabled' : ''}>取消</button><button type="button"${busy ? ' disabled' : ''}>−　最小化到托盘</button><button class="is-danger" type="button"${busy ? ' disabled' : ''}>${busy ? '正在处理…' : '⏻　退出应用'}</button></div></section>`;
  }

  function qingyuanShellMarkup(activeDestination) {
    const compactActive = ['主页', '教务', '课表', '信息'].includes(activeDestination) ? activeDestination : '更多';
    const desktopNavigation = qingyuanDestinations.map(([icon, label]) => `<button class="reference-shell-destination${label === activeDestination ? ' is-active' : ''}" type="button"${label === activeDestination ? ' aria-current="page"' : ''}><span aria-hidden="true">${icon}</span><strong>${label}</strong></button>`).join('');
    const compactNavigation = qingyuanDestinations.slice(0, 4).concat([['•••', '更多']]).map(([icon, label]) => `<button class="reference-shell-destination${label === compactActive ? ' is-active' : ''}" type="button"${label === compactActive ? ' aria-current="page"' : ''}><span aria-hidden="true">${icon}</span><strong>${label}</strong></button>`).join('');
    return `<section class="reference-qingyuan-shell"><aside class="reference-shell-rail"><div class="reference-shell-brand" aria-label="工大聚合">工</div><nav>${desktopNavigation}</nav></aside><main><header>清源导航</header><div class="reference-shell-empty"><span aria-hidden="true">⌂</span><h1>校园服务都在这里</h1><p>主目的地随窗口宽度切换为底栏、紧凑导航轨或扩展导航轨。</p></div><nav class="reference-shell-bottom">${compactNavigation}</nav></main></section>`;
  }

  function moreDrawerMarkup() {
    const shell = qingyuanShellMarkup('邮箱');
    const drawer = '<div class="reference-more-scrim"></div><section class="reference-more-drawer" role="dialog" aria-modal="true" aria-labelledby="reference-more-title"><h2 id="reference-more-title">更多</h2><button class="is-selected" type="button" aria-current="page"><span>✉</span><strong>邮箱</strong><small>查看学校邮件</small><b>✓</b></button><button type="button"><span>↗</span><strong>跳转</strong><small>打开校园服务</small><b>›</b></button><button type="button"><span>⚙</span><strong>设置</strong><small>管理本地数据</small><b>›</b></button></section>';
    return `${shell}${drawer}`;
  }

  function startupSurfaceMarkup(state) {
    const error = state === 'error';
    return `<section class="reference-global-stage reference-startup-stage"><article class="reference-startup-panel"><div class="reference-security-mark" aria-hidden="true">源</div><p class="reference-eyebrow">应用启动</p><h1>${error ? '暂时无法启动' : '正在准备清源'}</h1><p>${error ? '本地设置或缓存还未就绪，没有访问校园服务。' : '先恢复本地设置与安全状态，再决定是否访问校园服务。'}</p>${error ? '<div class="reference-banner is-error">本地存储不可用；请检查应用数据目录权限后重试。</div><button class="reference-startup-action" type="button">重试启动</button>' : '<div class="reference-startup-progress"><i></i></div><ol><li class="is-current">读取本地设置</li><li>恢复账户状态</li><li>准备校园服务</li></ol>'}</article></section>`;
  }

  function specialSurfaceMarkup(entry, state) {
    const componentSurface = window.qingyuanComponentReference?.render(entry);
    if (componentSurface) return componentSurface;
    const wechatLogin = window.qingyuanWechatLoginReference?.render(entry, state);
    if (wechatLogin) return wechatLogin;
    const settingsTask = window.qingyuanSettingsDialogReference.renderSettingsTask(
      entry,
      state,
      copyFor,
    );
    if (settingsTask) return settingsTask;
    const taskDialog = window.qingyuanSettingsDialogReference.renderTask(
      entry,
      state,
      qingyuanShellMarkup,
    );
    if (taskDialog) return taskDialog;
    const dataConfirmation = window.qingyuanSettingsDialogReference.renderDataConfirmation(
      entry,
      state,
      qingyuanShellMarkup,
    );
    if (dataConfirmation) return dataConfirmation;
    if (entry.id === 'shell.startup') return startupSurfaceMarkup(state);
    if (entry.id === 'shell.navigation') return qingyuanShellMarkup('主页');
    if (entry.id === 'shell.more-drawer') return moreDrawerMarkup();
    if (entry.id === 'shell.close-confirmation') return closeConfirmationMarkup(state);
    if (entry.id === 'consent.first-run') return consentSurfaceMarkup(state);
    if (entry.id === 'security.lock') return lockSurfaceMarkup(state);
    if (entry.id === 'external.system-auth') return lockSurfaceMarkup(state, true);
    if (entry.id === 'external.webview') return webViewSurfaceMarkup(entry, state);
    if (entry.id === 'academic.calendar') return calendarSurfaceMarkup(entry, state);
    if (entry.id === 'external.pdf') return pdfSurfaceMarkup(entry, state);
    if (entry.id === 'schedule.calendar') return scheduleSurfaceMarkup(entry, state);
    if (['academic.grade-detail', 'academic.exam-detail', 'academic.grade-process'].includes(entry.id)) return academicEamsSurfaceMarkup(entry, state);
    if (entry.id === 'academic.student-report') return academicDetailStateMarkup(entry, state, 'var(--service-secondclass)');
    if (entry.id === 'academic.student-report-rules') return window.qingyuanStudentReportRulesReference.render(entry, state);
    if (entry.id === 'academic.sports-attendance') return academicDetailStateMarkup(entry, state, 'var(--service-sports)');
    return null;
  }

  function contentMarkup(entry, state) {
    const id = entry.id;
    const special = specialSurfaceMarkup(entry, state);
    if (special) return special;
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
        return `<section class="reference-card reference-settings-list"><div class="reference-banner is-warn reference-settings-status">${description}</div>${entry.items.map((item, index) => `<div class="reference-setting-row"><span><strong>${rows?.[index]?.label ?? item}</strong><small>保留当前设置</small></span><button type="button" disabled>处理中</button></div>`).join('')}</section>`;
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
        return `<section class="reference-card reference-settings-list"><div class="reference-banner is-error reference-settings-status">${description}</div>${entry.items.map((item, index) => {
          const row = rows?.[index];
          return `<div class="reference-setting-row"><span><strong>${row?.prefix ?? (index === 0 ? '已完成：' : '未完成：')}${row?.label ?? item}</strong><small>${row?.status ?? (index === 0 ? '结果已保留' : '可安全重试')}</small></span><button type="button">${row?.action ?? (index === 0 ? '查看' : '重试')}</button></div>`;
        }).join('')}</section>`;
      }
      const symbol = state === 'error' ? '!' : state === 'empty' ? '○' : '→';
      const settingsStateClass = id.startsWith('settings.') ? ' reference-settings-empty' : '';
      return `<section class="reference-card reference-empty${settingsStateClass}"><div><span class="reference-symbol" aria-hidden="true">${symbol}</span><span class="reference-state-label">${status}</span><h2>${heading}</h2><p>${description}</p><div class="reference-state-context">${entry.items.map(item => `<span>${item}</span>`).join('')}</div><button type="button">${state === 'error' ? '检查后重试' : state === 'empty' ? '调整范围' : entry.primaryAction}</button></div></section>`;
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
      const checkingUpdate = entry.id === 'settings.update' && state === 'loading';
      headingAction.textContent = checkingUpdate ? '检查中' : entry.primaryAction;
      headingAction.hidden = entry.id.startsWith('components.') || entry.id === 'mail.compose';
      headingAction.disabled = state === 'operation-locked' || checkingUpdate;
      document.querySelector('[data-reference-source-detail]').textContent = `${entry.sourceSymbol || groupIcon}  ${entry.source}`;
      document.querySelector('.reference-source-strip time').hidden = entry.sourceTimestamp === false;
      const stateHost = document.querySelector('[data-reference-state]');
      stateHost.innerHTML = contentMarkup(entry, state);
      window.qingyuanStudentReportRulesReference?.bind(stateHost);
      const externalReturnFocus = entry.id === 'settings.licenses'
        ? stateHost.querySelector('.reference-license-link')
        : stateHost.querySelector('[data-reference-external-trigger]') ?? document.querySelector('[data-reference-more]');
      if (state === 'external-confirmation') {
        externalReturnFocus?.focus();
        window.qingyuanReferenceModal.prepare(externalReturnFocus);
      } else if (state === 'external-cancelled' && entry.id === 'settings.about') {
        externalReturnFocus?.focus();
      } else if (entry.id.startsWith('settings.confirm-')) {
        const dataReturnFocus = [...stateHost.querySelectorAll('.reference-shell-destination.is-active')]
          .find(target => target.offsetParent !== null);
        dataReturnFocus?.focus();
        window.qingyuanReferenceModal.prepare(dataReturnFocus);
      }
      document.body.dataset.surface = entry.id;
      document.body.dataset.state = state;
    },
  };
})();
