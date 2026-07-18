/*
 * 清源设计系统 · 组件样例共享脚本
 * @Project : SSPU-AllinOne / 工大聚合
 * @File    : docs/design/components/samples/_qingyuan.js
 * @Author  : Qintsg
 * @Date    : 2026-06-16
 *
 * 提供：主题切换（持久化 + 跟随系统）+ 通用组件交互（switch / check / radio / seg / chip / tab / stepper）。
 * 样例页只需在末尾 <script src="_qingyuan.js"></script> 即可获得全部交互。
 */
(function () {
  // ---- 主题切换 ----
  var KEY = 'qingyuan:samples:theme';
  function applyTheme(t) {
    document.documentElement.setAttribute('data-theme', t === 'dark' ? 'dark' : '');
    var btn = document.querySelector('.theme-toggle');
    if (btn) {
      var lab = btn.querySelector('.tt-label');
      if (lab) lab.textContent = t === 'dark' ? '浅色' : '深色';
      btn.setAttribute('aria-pressed', String(t === 'dark'));
    }
  }
  var saved = null;
  try { saved = localStorage.getItem(KEY); } catch (e) {}
  if (saved !== 'light' && saved !== 'dark') {
    saved = (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light';
  }
  applyTheme(saved);

  document.addEventListener('click', function (e) {
    var t = e.target.closest('.theme-toggle');
    if (!t) return;
    var next = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    try { localStorage.setItem(KEY, next); } catch (err) {}
    applyTheme(next);
  });

  // ---- 通用组件交互 ----
  document.addEventListener('click', function (e) {
    // 密码可见性切换：后置图标带 data-pw，切换同 .control 内 input 的 type
    var pw = e.target.closest('.ic.suffix[data-pw]');
    if (pw) {
      var inp = pw.closest('.control').querySelector('input');
      if (inp) { inp.type = inp.type === 'password' ? 'text' : 'password'; pw.classList.toggle('on'); }
      return;
    }

    // Select：选项点击
    var selOpt = e.target.closest('.yh-select-menu .opt');
    if (selOpt) {
      var selW = selOpt.closest('.yh-select');
      selW.querySelectorAll('.opt').forEach(function (o) { o.classList.remove('sel'); });
      selOpt.classList.add('sel');
      var v = selW.querySelector('.control .val');
      v.textContent = selOpt.dataset.label || selOpt.firstChild.textContent.trim();
      v.classList.remove('placeholder');
      selW.classList.remove('open');
      return;
    }
    // Select：触发器开合
    var selCtrl = e.target.closest('.yh-select .control');
    if (selCtrl) {
      var s = selCtrl.closest('.yh-select');
      var wasOpen = s.classList.contains('open');
      document.querySelectorAll('.yh-select.open').forEach(function (x) { x.classList.remove('open'); });
      if (!wasOpen) s.classList.add('open');
      return;
    }
    // 其它点击：关闭已打开的下拉（不拦截后续处理）
    document.querySelectorAll('.yh-select.open').forEach(function (x) { x.classList.remove('open'); });

    // Accordion：折叠 / 展开
    var accHead = e.target.closest('.yh-accordion .head');
    if (accHead) { accHead.parentElement.classList.toggle('open'); return; }

    // Switch / Checkbox / Chip：切换 on（点控件本身或包裹它的 <label> 文字都生效）
    var toggle = e.target.closest('.yh-switch, .yh-check, .yh-chip');
    if (!toggle) {
      var labT = e.target.closest('label');
      if (labT) toggle = labT.querySelector('.yh-switch, .yh-check, .yh-chip');
    }
    if (toggle) {
      if (!toggle.disabled && !toggle.closest('[aria-disabled="true"], .is-disabled')) {
        toggle.classList.toggle('on');
      }
      return;
    }

    // Radio：组内互斥（组 = [data-radio-group] / .yh-radio-group / 最近含多个 radio 的祖先）
    var radio = e.target.closest('.yh-radio');
    if (!radio) {
      var labR = e.target.closest('label');
      if (labR) radio = labR.querySelector('.yh-radio');
    }
    if (radio) {
      if (radio.closest('[aria-disabled="true"], .is-disabled')) return;
      var group = radio.closest('[data-radio-group], .yh-radio-group');
      if (!group) {
        group = radio.parentElement;
        while (group && group !== document.body && group.querySelectorAll('.yh-radio').length < 2) {
          group = group.parentElement;
        }
        if (!group) group = radio.parentElement;
      }
      group.querySelectorAll('.yh-radio').forEach(function (r) { r.classList.remove('on'); });
      radio.classList.add('on');
      return;
    }

    // Segmented / Tabs / BottomNav / NavRail：组内互斥高亮
    var segBtn = e.target.closest('.yh-seg button, .yh-tabs button, .yh-bottomnav .item, .yh-navrail .item');
    if (segBtn) {
      segBtn.parentElement.querySelectorAll('button, .item').forEach(function (b) { b.classList.remove('on'); });
      segBtn.classList.add('on');
      return;
    }
    // Pagination：仅页码按钮互斥高亮（上下页除外）
    var pgBtn = e.target.closest('.yh-pagination button[data-page]');
    if (pgBtn) {
      pgBtn.closest('.yh-pagination').querySelectorAll('button[data-page]').forEach(function (b) { b.classList.remove('on'); });
      pgBtn.classList.add('on');
      return;
    }

    // Stepper：加减
    var step = e.target.closest('.yh-stepper button');
    if (step) {
      var wrap = step.closest('.yh-stepper');
      var val = wrap.querySelector('.val');
      var min = parseInt(wrap.dataset.min || '0', 10);
      var max = parseInt(wrap.dataset.max || '99', 10);
      var n = parseInt(val.textContent, 10) || 0;
      n += step.dataset.act === 'inc' ? 1 : -1;
      n = Math.max(min, Math.min(max, n));
      val.textContent = n;
      wrap.querySelectorAll('button').forEach(function (b) {
        b.disabled = (b.dataset.act === 'dec' && n <= min) || (b.dataset.act === 'inc' && n >= max);
      });
    }
  });

  // ---- 输入类：OTP 自动跳格 + Textarea 字数统计 ----
  document.addEventListener('input', function (e) {
    var cell = e.target.closest('.yh-otp input');
    if (cell) {
      cell.value = cell.value.replace(/\D/g, '').slice(0, 1);
      cell.classList.toggle('filled', !!cell.value);
      if (cell.value) { var nx = cell.nextElementSibling; if (nx && nx.matches('input')) nx.focus(); }
      return;
    }
    var ta = e.target.closest('textarea[data-max]');
    if (ta) {
      var max = parseInt(ta.dataset.max, 10);
      if (ta.value.length > max) ta.value = ta.value.slice(0, max);
      var field = ta.closest('.yh-field');
      var cnt = field && field.querySelector('.count');
      if (cnt) cnt.textContent = ta.value.length + ' / ' + max;
    }
  });
  document.addEventListener('keydown', function (e) {
    var cell = e.target.closest('.yh-otp input');
    if (cell && e.key === 'Backspace' && !cell.value) {
      var pv = cell.previousElementSibling;
      if (pv && pv.matches('input')) { pv.focus(); }
    }
  });
})();
