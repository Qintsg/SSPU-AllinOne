(function () {
  var main = document.querySelector('.prototype-main');
  var moreButton = document.querySelector('[data-more]');
  var moreSheet = document.querySelector('.more-sheet');
  var moreTrigger = null;
  var scheduleDays = [
    [{ time: '08:00 · 1–2 节', title: '高等数学', place: '教三 401', domain: 'academic' }],
    [{ time: '10:00 · 3–4 节', title: '离散数学', place: '教一 201', domain: 'schedule' }],
    [{ time: '08:00 · 1–2 节', title: '大学英语', place: '教二 302', domain: 'schedule' }, { time: '10:00 · 3–4 节', title: '数据结构', place: '教二 302', domain: 'academic' }],
    [{ time: '13:30 · 5–6 节', title: '大学体育', place: '南操场', domain: 'sports' }],
    [{ time: '08:00 · 1–2 节', title: '操作系统', place: '实训楼 205', domain: 'academic' }]
  ];
  var mailDetails = [
    { sender: '财务处', time: '今天 08:12', title: '校园卡消费提醒', body: '您于 08:10 在学生食堂完成一笔 12.50 元消费，当前校园卡余额为 128.50 元。' },
    { sender: '教务处', time: '昨天 16:42', title: '夏季学期选课确认', body: '请在规定时间内确认选课结果；如课程与培养方案不一致，请联系学院教务老师。' },
    { sender: '图书馆', time: '7 月 16 日', title: '图书归还提醒', body: '您借阅的图书将在 3 天后到期，可在图书馆入口查看详情或办理续借。' }
  ];

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
    if (main) main.scrollTop = 0;
    window.scrollTo(0, 0);
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
      var tabs = Array.from(tab.closest('[role="tablist"]').querySelectorAll('[role="tab"]'));
      tabs.forEach(function (item) {
        item.setAttribute('aria-selected', String(item === tab));
      });
      var dayList = document.querySelector('.schedule-day-list');
      dayList.setAttribute('aria-label', tab.textContent.trim() + '课程');
      dayList.innerHTML = scheduleDays[tabs.indexOf(tab)].map(function (course) {
        return '<article class="day-course"><time>' + course.time + '</time><div class="course-chip" style="--domain:var(--service-' + course.domain + ')"><b>' + course.title + '</b><span>' + course.place + '</span></div></article>';
      }).join('');
      return;
    }

    var sourceFilter = event.target.closest('.filter-panel .filter-list button');
    if (sourceFilter) {
      sourceFilter.parentElement.querySelectorAll('button').forEach(function (item) {
        item.classList.toggle('is-active', item === sourceFilter);
      });
      var source = sourceFilter.textContent.split('·')[0].trim();
      document.querySelectorAll('.feed-entry').forEach(function (entry) {
        entry.hidden = source !== '全部信息' && entry.textContent.indexOf(source) < 0;
      });
      return;
    }

    var mailItem = event.target.closest('.mail-item');
    if (mailItem) {
      var mailItems = Array.from(mailItem.parentElement.querySelectorAll('.mail-item'));
      mailItems.forEach(function (item) { item.classList.toggle('is-active', item === mailItem); });
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
      settingsButton.parentElement.querySelectorAll('button').forEach(function (item) {
        item.classList.toggle('is-active', item === settingsButton);
      });
      var section = settingsButton.dataset.settingsSection;
      document.querySelectorAll('[data-settings-panel]').forEach(function (panel) {
        panel.hidden = panel.dataset.settingsPanel !== section;
      });
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
  });

  document.addEventListener('keydown', function (event) {
    if (!moreSheet || !moreSheet.classList.contains('is-open')) return;
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
    }
  });

  window.addEventListener('hashchange', function () {
    showPage(location.hash.slice(1) || 'home', false);
  });

  var initial = location.hash.slice(1);
  showPage(initial || 'home', false);
})();
