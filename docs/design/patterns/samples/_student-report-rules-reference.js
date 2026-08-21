/*
 * 第二课堂积分规则页设计参考 — 响应式完成差额与分类账本。
 * @Project : SSPU-AllinOne
 * @File : _student-report-rules-reference.js
 * @Author : Qintsg
 * @Date : 2026-08-14
 */

(function () {
  'use strict';

  const categories = [
    {
      id: 'lecture',
      name: '报告讲座',
      earned: '0.5',
      required: '1',
      status: '进行中',
      tone: 'progress',
      rules: [
        {item: '通识讲座', condition: '校级 · 3 场', credit: '+1', earned: '已获 0.5'},
      ],
    },
    {
      id: 'practice',
      name: '社会实践',
      earned: '2',
      required: '2',
      status: '已通过',
      tone: 'success',
      rules: [
        {item: '志愿服务', condition: '校级 · 累计 20 小时', credit: '+2', earned: '已获 2'},
      ],
    },
    {
      id: 'innovation',
      name: '创新创业',
      earned: '1.5',
      required: '1',
      status: '已通过',
      tone: 'success',
      rules: [
        {item: '创新训练项目', condition: '校级 · 完成结项', credit: '+1.5', earned: '已获 1.5'},
      ],
    },
  ];

  /**
   * 构造单个类别的规则明细。
   *
   * :param category: 类别参考数据。
   * :param compact: 是否用于窄屏连续账本。
   * :returns: 类别明细 HTML。
   */
  function categoryMarkup(category, compact) {
    const rows = category.rules.map(rule => `<article class="reference-student-rule-row"><div><strong>${rule.item}</strong><small>${rule.condition}</small></div><span><strong>${rule.credit}</strong><small>${rule.earned}</small></span></article>`).join('');
    return `<section class="reference-student-rule-category is-${category.tone}"${compact ? '' : ` data-rule-detail="${category.id}"${category.id === 'lecture' ? '' : ' hidden'}`}><header><div><small>${compact ? '计分类别' : '优先补齐'}</small><h2>${category.name}</h2></div><span><strong>${category.earned} / ${category.required}</strong><small>${category.status}</small></span></header><div class="reference-student-rule-progress" aria-label="${category.name} ${category.earned} / ${category.required}"><i style="--rule-progress:${category.id === 'lecture' ? '50%' : '100%'}"></i></div>${rows}</section>`;
  }

  /**
   * 构造积分规则页正常内容。
   *
   * :returns: 正常内容 HTML。
   */
  function contentMarkup() {
    const tabs = categories.map(category => `<button type="button" role="tab" aria-selected="${category.id === 'lecture'}" aria-controls="reference-rule-panel" data-rule-category="${category.id}"><span><strong>${category.name}</strong><small>${category.status}</small></span><b>${category.earned} / ${category.required}</b></button>`).join('');
    return `<section class="reference-student-rules-layout"><aside class="reference-student-rules-summary"><small>完成差额</small><div class="reference-student-rules-total"><strong>8.5 / 10</strong><span>还差 1.5 分</span></div><div class="reference-student-rules-progress" aria-label="总完成度 85%"><i></i></div><p>已完成 85%，先补齐报告讲座。</p><div class="reference-student-rules-nav" role="tablist" aria-label="计分类别">${tabs}</div></aside><main class="reference-student-rules-detail" id="reference-rule-panel" role="tabpanel">${categories.map(category => categoryMarkup(category, false)).join('')}</main><div class="reference-student-rules-compact">${categories.map(category => categoryMarkup(category, true)).join('')}</div></section>`;
  }

  /**
   * 构造积分规则页空状态。
   *
   * :returns: 空状态 HTML。
   */
  function emptyMarkup() {
    return `<section class="reference-student-rules-empty"><small>规则未同步</small><h2>暂时没有可核验的积分规则</h2><p>返回成绩单刷新第二课堂数据；规则补全后，本页会优先显示还差多少和可补齐的类别。</p><div><span>总差额</span><strong>等待规则数据</strong></div></section>`;
  }

  /**
   * 构造完整规则页参考。
   *
   * :param entry: 视觉清单中的页面条目。
   * :param state: 页面状态。
   * :returns: 完整页面 HTML。
   */
  function render(entry, state) {
    const body = state === 'empty' ? emptyMarkup() : contentMarkup();
    return `<section class="reference-academic-task reference-student-rules-task" style="--academic-accent:var(--service-secondclass)"><header class="reference-academic-appbar"><button type="button" aria-label="返回">←</button><span><small>${entry.kicker}</small><strong>第二课堂规则 · 08:42</strong></span><button type="button" aria-label="更多操作">•••</button></header><main class="reference-academic-scroll"><div class="reference-academic-content"><section class="reference-academic-heading"><div><small>${entry.kicker}</small><h1>${entry.title}</h1><p>${entry.summary}</p></div><button type="button">${entry.primaryAction}</button></section><div class="reference-academic-source"><i aria-hidden="true"></i><span>学　第二课堂 · 本地快照</span><time>2026-07-18 · 08:42</time></div>${body}</div></main></section>`;
  }

  /**
   * 绑定宽屏类别选择和方向键行为。
   *
   * :param host: 当前状态内容宿主。
   * :returns: 无返回值。
   */
  function bind(host) {
    const tabs = Array.from(host.querySelectorAll('[data-rule-category]'));
    const details = Array.from(host.querySelectorAll('[data-rule-detail]'));

    /**
     * 选择一个类别并同步互斥语义与明细。
     *
     * :param tab: 目标类别按钮。
     * :param moveFocus: 是否把键盘焦点移动到目标按钮。
     * :returns: 无返回值。
     */
    function select(tab, moveFocus) {
      tabs.forEach(candidate => candidate.setAttribute('aria-selected', String(candidate === tab)));
      details.forEach(detail => { detail.hidden = detail.dataset.ruleDetail !== tab.dataset.ruleCategory; });
      if (moveFocus) tab.focus();
    }
    tabs.forEach((tab, index) => {
      tab.addEventListener('click', () => select(tab, false));
      tab.addEventListener('keydown', event => {
        if (!['ArrowDown', 'ArrowUp', 'ArrowRight', 'ArrowLeft'].includes(event.key)) return;
        event.preventDefault();
        const forward = event.key === 'ArrowDown' || event.key === 'ArrowRight';
        select(tabs[(index + (forward ? 1 : tabs.length - 1)) % tabs.length], true);
      });
    });
  }

  window.qingyuanStudentReportRulesReference = {render, bind};
})();
