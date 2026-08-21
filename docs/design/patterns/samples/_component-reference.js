/*
 * 清源组件工作台参考结构
 * @Project : SSPU-AllinOne
 * @File : _component-reference.js
 * @Author : Qintsg
 * @Date : 2026-08-17
 */

(() => {
  const catalog = {
    'components.actions': {
      title: '操作组件',
      summary: '行动、选择与进度控件共享明确层级，危险与禁用状态不靠尺寸夸张。',
      cards: [
        ['按钮与行动', '主要、次要、禁用与图标行动', `<div class="reference-component-showcase"><button class="reference-component-button is-primary">主要操作</button><button class="reference-component-button is-secondary">次要操作</button><button class="reference-component-button" disabled>禁用操作</button><button class="reference-component-icon-button" aria-label="刷新">↻</button><button class="reference-component-fab">＋ 新建</button></div>`],
        ['选择与开关', '单选、复选和分段选择保持同一命中节奏', `<div class="reference-component-showcase"><div class="reference-component-segmented" role="radiogroup" aria-label="时间范围"><button data-component-segment role="radio" aria-checked="false" tabindex="-1">日</button><button data-component-segment class="is-selected" role="radio" aria-checked="true" tabindex="0">周</button><button data-component-segment role="radio" aria-checked="false" tabindex="-1">月</button></div><button data-component-toggle class="reference-component-chip is-selected" aria-pressed="true">✓ 已选择</button><button data-component-toggle class="reference-component-chip" aria-pressed="false">筛选项</button><button data-component-switch class="reference-component-switch" role="switch" aria-checked="true" aria-label="通知"></button><button data-component-toggle class="reference-component-choice" aria-pressed="true">同意协议</button><button data-component-radio class="reference-component-choice is-radio" role="radio" aria-checked="true">校内服务</button></div>`],
        ['连续进度', '滑块与步骤状态表达当前位置和下一步', `<div class="reference-component-showcase is-column"><div data-component-slider class="reference-component-slider" role="slider" tabindex="0" aria-label="透明度" aria-valuemin="0" aria-valuemax="100" aria-valuenow="68" style="--component-progress: 68%"><span></span></div><div class="reference-component-stepper"><span class="is-complete" data-step="1">填写</span><span class="is-complete" data-step="2">确认</span><span data-step="3">完成</span></div></div>`],
      ],
    },
    'components.inputs': {
      title: '输入组件',
      summary: '持续标签、帮助文本与错误说明共同保留输入上下文，不把占位符当标签。',
      cards: [
        ['文字输入', '普通、搜索与多行输入', `<div class="reference-component-showcase"><label class="reference-component-field">姓名<input placeholder="请输入姓名" /></label><label class="reference-component-field is-search">搜索<input placeholder="搜索课程、邮件或资讯" /></label><label class="reference-component-field">备注<textarea placeholder="补充说明"></textarea></label></div>`, 'is-wide'],
        ['结构化选择', '学期与日期使用持续可见标签', `<div class="reference-component-showcase is-column"><label class="reference-component-field is-select">学期<select><option>2026 夏季学期</option></select></label><label class="reference-component-field is-date">查询日期<input value="2026-07-19" /></label></div>`],
        ['验证码与错误', '定长输入和错误恢复靠近对应字段', `<div class="reference-component-showcase is-column"><label class="reference-component-field">验证码<input value="260719" inputmode="numeric" maxlength="6" /></label><label class="reference-component-field is-error">邮箱<input value="student@" /><span>邮箱格式不正确</span></label></div>`],
      ],
    },
    'components.feedback': {
      title: '容器与反馈',
      summary: '容器只组织真实上下文；提示、空状态和确认行动说明现在发生什么。',
      cards: [
        ['内容容器', '卡片、磁贴、列表与折叠说明', `<div class="reference-component-showcase is-column"><div class="reference-component-surface">用于组织关联内容的清源卡片</div><div class="reference-component-surface">可选择的内容磁贴</div><div class="reference-component-list"><strong>校园通知</strong><small>刚刚更新</small></div><details class="reference-component-disclosure" open><summary>查看说明</summary><small>折叠内容遵循清源间距与焦点规范。</small></details></div>`],
        ['即时反馈', '状态横幅、保存 Toast 与加载骨架', `<div class="reference-component-showcase is-column"><div class="reference-component-banner">ⓘ 数据已在 09:30 更新</div><div class="reference-component-toast"><span>设置已保存</span><button data-component-undo>撤销</button></div><div class="reference-component-skeleton"></div></div>`],
        ['空状态与确认', '没有内容时给出方向，危险决定保留取消', `<div class="reference-component-showcase is-column"><div class="reference-component-empty"><span class="reference-component-empty-icon">▱</span><strong>暂无内容</strong><span>完成同步后将在这里显示。</span></div><div class="reference-component-dialog"><strong>确认操作</strong><p>该操作会更新本地显示设置。</p><footer><button class="reference-component-button is-secondary">取消</button><button class="reference-component-button is-primary">确认</button></footer></div></div>`],
      ],
    },
    'components.navigation': {
      title: '导航组件',
      summary: '目的地、页内分段和分页共享清晰选中态，空间变化不改变顺序。',
      cards: [
        ['页内导航', '标签与分页保留当前上下文', `<div class="reference-component-showcase is-column"><div class="reference-component-tabs" role="tablist" aria-label="内容分段"><button data-component-tab class="reference-component-tab is-selected" role="tab" aria-selected="true" tabindex="0">⌂ 总览</button><button data-component-tab class="reference-component-tab" role="tab" aria-selected="false" tabindex="-1">ⓘ 详情</button></div><div class="reference-component-pagination" aria-label="分页"><button class="reference-component-page" aria-label="上一页">←</button><button data-component-page class="reference-component-page">2</button><button data-component-page class="reference-component-page is-selected" aria-current="page">3</button><button data-component-page class="reference-component-page">4</button><button class="reference-component-page" aria-label="下一页">→</button></div></div>`, 'is-wide'],
        ['紧凑目的地', '底栏以同一顺序表达三个主目的地', `<nav class="reference-component-bottom-nav" aria-label="主要目的地"><button data-component-destination class="is-selected" aria-pressed="true">⌂<small>主页</small></button><button data-component-destination aria-pressed="false">学<small>教务</small></button><button data-component-destination aria-pressed="false">周<small>课表</small></button></nav>`],
        ['纵向目的地', '空间充足时切换为导航轨', `<nav class="reference-component-rail" aria-label="宽屏目的地"><button data-component-destination class="is-selected" aria-pressed="true">⌂<small>主页</small></button><button data-component-destination aria-pressed="false">⚙<small>设置</small></button></nav>`],
      ],
    },
    'components.data': {
      title: '数据展示',
      summary: '指标、进度、来源和时间共同出现，数值不脱离证据上下文。',
      cards: [
        ['状态与身份', '数量、运行状态和用户身份使用紧凑标记', `<div class="reference-component-badges"><span class="reference-component-badge">12</span><span class="reference-component-pill">● 运行正常</span><span class="reference-component-pill is-warn">● 需要关注</span><span class="reference-component-avatar">清</span></div>`],
        ['指标与进度', '比较值与完成度保留解释', `<div class="reference-component-showcase is-column"><div class="reference-component-metric"><small>平均绩点</small><strong>3.82</strong><small>较上学期 +0.12</small></div><div class="reference-component-progress"></div><div class="reference-component-ring">82%</div></div>`],
        ['来源记录', '列表项目同时呈现摘要、来源和时间', `<div class="reference-component-showcase is-column"><article class="reference-component-feed"><strong>夏季学期选课确认</strong><p>请在规定时间内登录教务系统确认选课结果。</p><small>教务处 · 09:30</small></article><span class="reference-component-source">◎ 学校官网</span></div>`],
      ],
    },
    'components.domain': {
      title: '校园域组件',
      summary: '课程、余额、考勤和校园服务保留域色，但不争夺页面结构层级。',
      cards: [
        ['今日与课程', '日程先表达时间，再表达课程地点', `<div class="reference-component-showcase is-column"><article class="reference-component-today"><header><strong>今天</strong><small>7 月 19 日 · 星期日</small></header><p>2 节课程 · 1 项待办</p></article><article class="reference-component-course"><strong>高等数学</strong><small>08:00–09:35 · 教学楼 310</small></article></div>`],
        ['校园服务', '余额、快捷入口和更新时间保持同一证据层级', `<div class="reference-component-showcase is-column"><article class="reference-component-surface reference-component-balance"><small>校园卡余额</small><strong>¥ 88.00</strong><small>更新于 09:30</small></article><div class="reference-component-quick">书 <span><strong>图书馆</strong><small>馆藏与借阅</small></span></div></div>`],
        ['消息与考勤', '摘要与状态只表达当前事实', `<div class="reference-component-showcase is-column"><div class="reference-component-message">已为你整理今天的课程与待办。</div><article class="reference-component-attendance"><span><strong>体育考勤</strong><small>操场 · 07:30</small></span><span class="reference-component-pill">已签到</span></article></div>`],
      ],
    },
  };

  function cardMarkup(card, index) {
    const [title, summary, sample, className = ''] = card;
    return `<article class="reference-component-card ${className}"><header><span>${String(index + 1).padStart(2, '0')}</span><div><strong>${title}</strong><small>${summary}</small></div></header>${sample}</article>`;
  }

  /**
   * 在同一组件组内切换唯一选中项。
   *
   * :param {HTMLElement} target: 新的选中项。
   * :param {string} selector: 同组项目选择器。
   * :param {string} attribute: 表达选中状态的 ARIA 属性。
   * :returns {void}: 无返回值。
   */
  function activateWithinGroup(target, selector, attribute) {
    target.parentElement.querySelectorAll(selector).forEach((item) => {
      const selected = item === target;
      item.classList.toggle('is-selected', selected);
      if (attribute === 'aria-current') {
        if (selected) item.setAttribute(attribute, 'page');
        else item.removeAttribute(attribute);
      } else {
        item.setAttribute(attribute, String(selected));
      }
      if (attribute === 'aria-checked' || attribute === 'aria-selected') {
        item.tabIndex = selected ? 0 : -1;
      }
    });
  }

  /**
   * 判断事件目标是否属于当前组件工作台。
   *
   * :param {EventTarget|null} eventTarget: 原始事件目标。
   * :param {string} selector: 需要匹配的控件选择器。
   * :returns {HTMLElement|null}: 匹配控件，或空值。
   */
  function componentTarget(eventTarget, selector) {
    const target = eventTarget instanceof Element ? eventTarget.closest(selector) : null;
    return target?.closest('.reference-component-stage') ? target : null;
  }

  /**
   * 将键盘方向映射到同组的前后项目。
   *
   * :param {KeyboardEvent} event: 键盘事件。
   * :param {HTMLElement} target: 当前项目。
   * :param {string} selector: 同组项目选择器。
   * :param {string} attribute: 表达选中状态的 ARIA 属性。
   * :returns {boolean}: 是否处理了本次按键。
   */
  function moveGroupSelection(event, target, selector, attribute) {
    const direction = ['ArrowRight', 'ArrowDown'].includes(event.key)
      ? 1
      : ['ArrowLeft', 'ArrowUp'].includes(event.key)
        ? -1
        : 0;
    if (direction === 0) return false;
    const items = [...target.parentElement.querySelectorAll(selector)];
    const next = items[(items.indexOf(target) + direction + items.length) % items.length];
    activateWithinGroup(next, selector, attribute);
    next.focus();
    event.preventDefault();
    return true;
  }

  document.addEventListener('click', (event) => {
    const segment = componentTarget(event.target, '[data-component-segment]');
    if (segment) activateWithinGroup(segment, '[data-component-segment]', 'aria-checked');

    const tab = componentTarget(event.target, '[data-component-tab]');
    if (tab) activateWithinGroup(tab, '[data-component-tab]', 'aria-selected');

    const page = componentTarget(event.target, '[data-component-page]');
    if (page) activateWithinGroup(page, '[data-component-page]', 'aria-current');

    const destination = componentTarget(event.target, '[data-component-destination]');
    if (destination) activateWithinGroup(destination, '[data-component-destination]', 'aria-pressed');

    const toggle = componentTarget(event.target, '[data-component-toggle]');
    if (toggle) {
      const selected = toggle.getAttribute('aria-pressed') !== 'true';
      toggle.setAttribute('aria-pressed', String(selected));
      toggle.classList.toggle('is-selected', selected);
    }

    const radio = componentTarget(event.target, '[data-component-radio]');
    if (radio) {
      const selected = radio.getAttribute('aria-checked') !== 'true';
      radio.setAttribute('aria-checked', String(selected));
      radio.classList.toggle('is-selected', selected);
    }

    const componentSwitch = componentTarget(event.target, '[data-component-switch]');
    if (componentSwitch) {
      componentSwitch.setAttribute(
        'aria-checked',
        String(componentSwitch.getAttribute('aria-checked') !== 'true'),
      );
    }

    const undo = componentTarget(event.target, '[data-component-undo]');
    if (undo) {
      undo.parentElement.querySelector('span').textContent = '更改已撤销';
      undo.textContent = '已撤销';
      undo.disabled = true;
    }
  });

  document.addEventListener('keydown', (event) => {
    const segment = componentTarget(event.target, '[data-component-segment]');
    if (segment && moveGroupSelection(event, segment, '[data-component-segment]', 'aria-checked')) return;

    const tab = componentTarget(event.target, '[data-component-tab]');
    if (tab && moveGroupSelection(event, tab, '[data-component-tab]', 'aria-selected')) return;

    const slider = componentTarget(event.target, '[data-component-slider]');
    if (!slider || !['ArrowLeft', 'ArrowDown', 'ArrowRight', 'ArrowUp'].includes(event.key)) return;
    const direction = ['ArrowRight', 'ArrowUp'].includes(event.key) ? 1 : -1;
    const value = Math.max(0, Math.min(100, Number(slider.getAttribute('aria-valuenow')) + direction * 4));
    slider.setAttribute('aria-valuenow', String(value));
    slider.style.setProperty('--component-progress', `${value}%`);
    event.preventDefault();
  });

  window.qingyuanComponentReference = {
    render(entry) {
      const definition = catalog[entry.id];
      if (!definition) return null;
      return `<section class="reference-component-stage"><header class="reference-component-appbar"><span>组件契约</span><strong>${definition.title}</strong></header><div class="reference-component-scroll"><main class="reference-component-main"><header class="reference-component-intro"><small>清源组件 · 0.4</small><h1>${definition.title}</h1><p>${definition.summary}</p></header><div class="reference-component-workbench-grid">${definition.cards.map(cardMarkup).join('')}</div></main></div></section>`;
    },
  };
})();
