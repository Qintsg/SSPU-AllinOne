(function () {
  var main = document.querySelector('.prototype-main');
  var moreButton = document.querySelector('[data-more]');
  var moreSheet = document.querySelector('.more-sheet');
  var moreTrigger = null;
  var scheduleDays = [
    [{ time: '08:00 · 1–2 节', title: '数据结构', place: '计算机楼 301', domain: 'schedule' }],
    [],
    [{ time: '11:25 · 5–6 节', title: '人机交互设计', place: '艺术楼 B204', domain: 'schedule' }],
    [],
    [],
    [{ time: '09:50 · 3–4 节', title: '软件工程实践', place: '实训中心 405', domain: 'schedule' }],
    []
  ];
  var mailDetails = [
    { sender: '教务处', time: '今天 08:12', title: '选课结果确认通知', body: '本学期选课结果已生效，请在课程表中核对上课时间与地点。' },
    { sender: '图书馆', time: '昨天 16:42', title: '图书馆借阅到期提醒', body: '您有 2 本图书即将到期，可在线办理续借。' },
    { sender: '信息化办公室', time: '7 月 16 日', title: '校园网络维护公告', body: '周日凌晨将进行短时网络维护。' }
  ];
  var settingsHeadings = {
    account: ['数据与连接', '先说明数据存在哪里、连接是否有效，再提供修改操作；高风险动作保持隔离。'],
    home: ['首页与通知', '决定首页先出现什么，以及哪些校园事项可以在本机提醒你。'],
    appearance: ['外观', '主题、密度与动态响应系统设置，内容层级保持不变。'],
    privacy: ['数据与隐私', '查看本机保存了什么，并逐项管理缓存、登录状态和个性化设置。'],
    about: ['关于工大聚合', '查看当前版本、开源许可、隐私政策与反馈入口。']
  };
  var toastTimer = null;

  function selectOne(items, selected, attribute) {
    items.forEach(function (item) {
      var active = item === selected;
      item.classList.toggle('is-active', active);
      item.classList.toggle('on', active);
      item.setAttribute(attribute, String(active));
      item.tabIndex = active ? 0 : -1;
    });
  }

  function showFeedback(message) {
    var toast = document.querySelector('.prototype-toast');
    if (!toast) return;
    window.clearTimeout(toastTimer);
    toast.textContent = message;
    toast.hidden = false;
    toastTimer = window.setTimeout(function () { toast.hidden = true; }, 2000);
  }

  function activateScheduleTab(tab) {
    var tabs = Array.from(tab.closest('[role="tablist"]').querySelectorAll('[role="tab"]'));
    selectOne(tabs, tab, 'aria-selected');
    var dayList = document.querySelector('.schedule-day-list');
    dayList.setAttribute('aria-label', tab.textContent.trim() + '课程');
    dayList.innerHTML = scheduleDays[tabs.indexOf(tab)].map(function (course) {
      return '<article class="day-course"><time>' + course.time + '</time><div class="course-chip" style="--domain:var(--service-' + course.domain + ')"><b>' + course.title + '</b><span>' + course.place + '</span></div></article>';
    }).join('');
    revealScheduleTab(tab);
  }

  function revealScheduleTab(tab) {
    if (!tab) return;
    var strip = tab.closest('.domain-tabs');
    if (!strip) return;
    var tabs = Array.from(strip.querySelectorAll('.domain-tab'));
    var start = tabs[Math.max(0, tabs.indexOf(tab) - 2)];
    strip.scrollLeft = start ? Math.max(0, start.offsetLeft - strip.offsetLeft) : 0;
  }

  function setMailState(state) {
    var mailPage = document.querySelector('[data-screen="mail"]');
    if (!mailPage) return;
    var showContent = state === 'content' || state === 'stale';
    mailPage.dataset.mailState = state;
    mailPage.classList.remove('is-composing');
    mailPage.querySelectorAll('[data-mail-content]').forEach(function (item) {
      item.hidden = !showContent;
    });
    var staleBanner = mailPage.querySelector('.mail-stale-banner');
    if (staleBanner) staleBanner.hidden = state !== 'stale';
    mailPage.querySelectorAll('[data-mail-state-panel]').forEach(function (panel) {
      panel.hidden = panel.dataset.mailStatePanel !== state;
    });
    var compose = mailPage.querySelector('[data-mail-compose-panel]');
    if (compose) compose.hidden = true;
    mailPage.querySelector('#mail-title').textContent = '收件箱';
    mailPage.querySelector('.page-heading p:not(.page-kicker)').textContent = '邮件原文只在本机读取；桌面采用列表—详情并列，移动端进入独立详情页。';
  }

  function setMailComposeState(state) {
    var mailPage = document.querySelector('[data-screen="mail"]');
    if (!mailPage) return;
    setMailState('content');
    mailPage.querySelectorAll('[data-mail-content]').forEach(function (item) { item.hidden = true; });
    var compose = mailPage.querySelector('[data-mail-compose-panel]');
    compose.hidden = false;
    compose.dataset.composeState = state;
    mailPage.classList.add('is-composing');
    mailPage.querySelector('#mail-title').textContent = '撰写邮件';
    mailPage.querySelector('.page-heading p:not(.page-kicker)').textContent = '填写收件人、主题与普通文本正文；发送前仍可取消。';
    var loading = state === 'loading';
    compose.querySelectorAll('input, textarea, button').forEach(function (control) {
      control.disabled = loading;
    });
    compose.querySelector('.mail-compose-error').hidden = state !== 'error';
    var send = compose.querySelector('[data-mail-send]');
    send.textContent = loading ? '正在发送' : '发送邮件';
  }

  function setLinksState(state) {
    var linksPage = document.querySelector('[data-screen="links"]');
    if (!linksPage) return;
    var showContent = state === 'content';
    linksPage.dataset.linksState = state;
    linksPage.querySelectorAll('[data-links-content]').forEach(function (item) {
      item.hidden = !showContent;
    });
    var searchEmpty = linksPage.querySelector('[data-search-empty]');
    if (searchEmpty) searchEmpty.hidden = true;
    linksPage.querySelectorAll('[data-links-state-panel]').forEach(function (panel) {
      panel.hidden = panel.dataset.linksStatePanel !== state;
    });
  }

  function closeMore(restoreFocus) {
    if (!moreSheet || !moreButton) return;
    var wasOpen = moreSheet.classList.contains('is-open');
    moreSheet.classList.remove('is-open');
    moreButton.setAttribute('aria-expanded', 'false');
    if (restoreFocus && wasOpen && moreTrigger) moreTrigger.focus();
  }

  function openMore(trigger) {
    if (!moreSheet) return;
    moreTrigger = trigger;
    moreSheet.classList.add('is-open');
    trigger.setAttribute('aria-expanded', 'true');
    moreSheet.querySelector('.more-item').focus();
  }

  function showPage(name, updateHash) {
    var target = document.querySelector('[data-screen="' + name + '"]');
    if (!target) return;
    document.querySelectorAll('[data-screen]').forEach(function (page) {
      var active = page === target;
      page.classList.toggle('is-active', active);
      page.hidden = !active;
    });
    document.body.classList.toggle('standalone-screen', name === 'mail-detail');
    document.querySelectorAll('[data-page]').forEach(function (button) {
      if (button.dataset.page === name) button.setAttribute('aria-current', 'page');
      else button.removeAttribute('aria-current');
    });
    if (moreButton) {
      var secondary = ['mail', 'links', 'settings'].indexOf(name) >= 0;
      if (secondary) moreButton.setAttribute('aria-current', 'page');
      else moreButton.removeAttribute('aria-current');
    }
    closeMore(true);
    var toast = document.querySelector('.prototype-toast');
    if (toast) toast.hidden = true;
    window.clearTimeout(toastTimer);
    if (main) main.scrollTop = 0;
    window.scrollTo(0, 0);
    revealScheduleTab(target.querySelector('.domain-tab[aria-selected="true"]'));
    if (updateHash) history.replaceState(null, '', '#' + name);
  }

  document.addEventListener('click', function (event) {
    var destination = event.target.closest('[data-page]');
    if (destination) {
      showPage(destination.dataset.page, true);
      return;
    }
    var trigger = event.target.closest('[data-more]');
    if (trigger && moreSheet) {
      var open = !moreSheet.classList.contains('is-open');
      if (open) openMore(trigger);
      else closeMore(true);
      return;
    }

    var tab = event.target.closest('.domain-tab');
    if (tab) {
      activateScheduleTab(tab);
      return;
    }

    var composeTrigger = event.target.closest('[data-mail-compose]');
    if (composeTrigger) {
      setMailComposeState('initial');
      var firstField = document.querySelector('[data-mail-compose-panel] input');
      if (firstField) firstField.focus();
      return;
    }

    var composeClose = event.target.closest('[data-mail-compose-close]');
    if (composeClose) {
      setMailState('content');
      var writeButton = Array.from(document.querySelectorAll('[data-mail-compose]')).find(function (button) {
        return button.offsetParent !== null;
      });
      if (writeButton) writeButton.focus();
      return;
    }

    var sourceFilter = event.target.closest('.filter-panel .filter-list button');
    if (sourceFilter) {
      selectOne(Array.from(sourceFilter.parentElement.querySelectorAll('button')), sourceFilter, 'aria-pressed');
      var source = sourceFilter.textContent.split('·')[0].trim();
      document.querySelectorAll('.feed-entry').forEach(function (entry) {
        entry.hidden = source !== '全部信息' && entry.textContent.indexOf(source) < 0;
      });
      return;
    }

    var mailItem = event.target.closest('.mail-item');
    if (mailItem) {
      var mailItems = Array.from(mailItem.parentElement.querySelectorAll('.mail-item'));
      selectOne(mailItems, mailItem, 'aria-selected');
      var detail = mailDetails[mailItems.indexOf(mailItem)];
      var content = document.querySelector('.mail-content');
      content.querySelector('.feed-meta span').textContent = detail.sender;
      content.querySelector('.feed-meta time').textContent = detail.time;
      content.querySelector('h2').textContent = detail.title;
      content.querySelector('.mail-body').textContent = detail.body;
      if (window.matchMedia('(max-width: 900px)').matches) {
        mailItem.closest('.mail-layout').classList.add('is-detail');
        content.focus();
      }
      return;
    }

    var mailBack = event.target.closest('.mail-back');
    if (mailBack) {
      var mailLayout = mailBack.closest('.mail-layout');
      mailLayout.classList.remove('is-detail');
      mailLayout.querySelector('.mail-item.is-active').focus();
      return;
    }

    var settingsButton = event.target.closest('.settings-nav .filter-list button');
    if (settingsButton) {
      selectOne(Array.from(settingsButton.parentElement.querySelectorAll('button')), settingsButton, 'aria-selected');
      var section = settingsButton.dataset.settingsSection;
      document.querySelectorAll('[data-settings-panel]').forEach(function (panel) {
        panel.hidden = panel.dataset.settingsPanel !== section;
      });
      var heading = settingsHeadings[section];
      document.querySelector('#settings-title').textContent = heading[0];
      document.querySelector('[data-screen="settings"] .page-heading p:not(.page-kicker)').textContent = heading[1];
      return;
    }

    var clearSearch = event.target.closest('[data-clear-search]');
    if (clearSearch) {
      var searchInput = document.querySelector('.search-box input[type="search"]');
      searchInput.value = '';
      searchInput.dispatchEvent(new Event('input', { bubbles: true }));
      searchInput.focus();
      return;
    }

    var pageAction = event.target.closest('.page-actions button');
    if (pageAction) {
      var action = pageAction.getAttribute('aria-label') || pageAction.textContent.trim();
      showFeedback(action + '已完成；当前展示为设计核验数据。');
    }
  });

  document.addEventListener('input', function (event) {
    var search = event.target.closest('.search-box input[type="search"]');
    if (!search) return;
    var query = search.value.trim().toLowerCase();
    document.querySelectorAll('.link-groups .section-card').forEach(function (section) {
      var visible = 0;
      section.querySelectorAll('.action-row').forEach(function (row) {
        var match = !query || row.textContent.toLowerCase().indexOf(query) >= 0;
        row.hidden = !match;
        if (match) visible += 1;
      });
      section.hidden = visible === 0;
    });
    var results = document.querySelectorAll('.link-groups .action-row:not([hidden])').length;
    document.querySelector('[data-search-empty]').hidden = results !== 0;
  });

  document.addEventListener('submit', function (event) {
    if (!event.target.matches('.mail-compose-form')) return;
    event.preventDefault();
    setMailComposeState('loading');
    showFeedback('邮件发送仅在原型中模拟；未访问真实 SMTP。');
  });

  document.addEventListener('keydown', function (event) {
    if (moreSheet && moreSheet.classList.contains('is-open')) {
      if (event.key === 'Escape') {
        event.preventDefault();
        closeMore(true);
        return;
      }
      if (event.key === 'Tab') {
        var items = Array.from(moreSheet.querySelectorAll('.more-item'));
        var first = items[0];
        var last = items[items.length - 1];
        if (event.shiftKey && document.activeElement === first) {
          event.preventDefault();
          last.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
          event.preventDefault();
          first.focus();
        }
        return;
      }
    }

    var current = event.target.closest('[data-roving] > button, [data-roving] .mail-item');
    if (!current) return;
    var group = current.closest('[data-roving]');
    var controls = Array.from(group.querySelectorAll(':scope > button, :scope > .mail-item'));
    var vertical = group.dataset.roving === 'options';
    var previousKey = vertical ? 'ArrowUp' : 'ArrowLeft';
    var nextKey = vertical ? 'ArrowDown' : 'ArrowRight';
    var index = controls.indexOf(current);
    if (event.key === previousKey) index = (index - 1 + controls.length) % controls.length;
    else if (event.key === nextKey) index = (index + 1) % controls.length;
    else if (event.key === 'Home') index = 0;
    else if (event.key === 'End') index = controls.length - 1;
    else return;
    event.preventDefault();
    controls[index].focus();
    controls[index].click();
  });

  window.addEventListener('hashchange', function () {
    showPage(location.hash.slice(1) || 'home', false);
  });

  var initial = location.hash.slice(1);
  document.querySelectorAll('[data-settings-panel]').forEach(function (panel) {
    var tab = document.querySelector('[data-settings-section="' + panel.dataset.settingsPanel + '"]');
    if (tab) panel.setAttribute('aria-labelledby', tab.id);
  });
  window.qingyuanPrototype = {
    setMailState: setMailState,
    setMailComposeState: setMailComposeState,
    setLinksState: setLinksState
  };
  showPage(initial || 'home', false);
})();
