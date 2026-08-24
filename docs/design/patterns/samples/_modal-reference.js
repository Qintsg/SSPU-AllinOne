/*
 * 清源参考模态交互 — 安全焦点、焦点循环、Escape 与焦点归还
 * @Project : SSPU-AllinOne
 * @File : _modal-reference.js
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

(() => {
  'use strict';

  let modalReturnFocus = null;

  /**
   * 查找当前真正可见的参考模态。
   *
   * :returns: 可见模态元素；不存在时返回 null。
   */
  function visibleModal() {
    return [...document.querySelectorAll('[data-reference-modal]')].find(modal => {
      const wrapper = modal.closest('.reference-modal-scrim');
      return !modal.hidden && !wrapper?.hidden;
    }) ?? null;
  }

  /**
   * 关闭当前模态并把焦点归还发起入口。
   *
   * :returns: 无返回值。
   */
  function close() {
    const modal = visibleModal();
    if (!modal) return;
    const wrapper = modal.closest('.reference-modal-scrim');
    if (wrapper) {
      wrapper.hidden = true;
    } else {
      modal.hidden = true;
      const taskScrim = document.querySelector('.reference-task-scrim');
      if (taskScrim) taskScrim.hidden = true;
    }
    if (modalReturnFocus?.isConnected) modalReturnFocus.focus();
  }

  /**
   * 激活模态安全焦点和取消行动。
   *
   * :param returnFocus: 关闭后需要恢复焦点的发起入口。
   * :returns: 无返回值。
   */
  function prepare(returnFocus) {
    const modal = visibleModal();
    if (!modal) return;
    modalReturnFocus = returnFocus;
    const cancel = modal.querySelector('[data-reference-modal-cancel]');
    cancel?.addEventListener('click', close);
    cancel?.focus();
  }

  document.addEventListener('keydown', event => {
    const modal = visibleModal();
    if (!modal) return;
    if (event.key === 'Escape') {
      event.preventDefault();
      close();
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

  window.qingyuanReferenceModal = {prepare, close};
})();
