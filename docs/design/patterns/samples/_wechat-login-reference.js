/*
 * 微信公众号扫码登录参考渲染 — 八态认证与恢复流程
 * @Project : SSPU-AllinOne
 * @File : _wechat-login-reference.js
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

(() => {
  'use strict';

  /**
   * 渲染公众号扫码登录的紧凑工具栏。
   *
   * :param state: 当前视觉状态。
   * :returns: 工具栏 HTML。
   */
  function toolbarMarkup(state) {
    const locked = state === 'loading' || state === 'operation-locked' || state === 'content';
    const backLabel = state === 'content' ? '完成' : state === 'operation-locked' ? '正在保存认证，暂不能返回' : '返回';
    return `<header class="reference-wechat-login-toolbar"><button type="button" aria-label="${backLabel}"${state === 'operation-locked' ? ' disabled' : ''}>←</button><strong>${state === 'content' ? '登录已完成' : '公众号平台登录'}</strong><button type="button" aria-label="刷新微信登录页"${locked ? ' disabled' : ''}>↻</button><button type="button" aria-label="在系统浏览器打开微信登录页" data-reference-external-trigger${locked ? ' disabled' : ''}>↗</button></header>`;
  }

  /**
   * 渲染由平台 WebView 绘制的确定性外部区域占位。
   *
   * :returns: 带外部区域标识的网页正文 HTML。
   */
  function documentMarkup() {
    return '<section class="reference-wechat-login-document" data-external-region="document"><div class="reference-wechat-login-qr" aria-hidden="true">码</div><strong>微信公众平台</strong><span>请使用微信扫码登录</span><small>此区域由对应平台 WebView 绘制</small></section>';
  }

  /**
   * 渲染当前认证责任与恢复方向。
   *
   * :param kind: 状态条语义种类。
   * :param text: 用户可执行的状态说明。
   * :returns: 认证接力条 HTML。
   */
  function handoffMarkup(kind, text) {
    const symbol = kind === 'is-success' ? '✓' : kind === 'is-error' ? '!' : kind === 'is-warn' ? '…' : 'i';
    return `<div class="reference-wechat-login-handoff ${kind}"><span aria-hidden="true">${symbol}</span><p>${text}</p></div>`;
  }

  /**
   * 渲染微信公众号扫码登录八态参考。
   *
   * :param entry: 当前视觉目录条目。
   * :param state: 当前冻结状态。
   * :returns: 匹配时返回扫码登录 HTML，否则返回 null。
   */
  function render(entry, state) {
    if (entry.id !== 'settings.wechat-login') return null;
    let body;
    if (state === 'loading') {
      body = '<section class="reference-wechat-login-loading"><div><span class="reference-spinner" aria-hidden="true"></span><h2>正在打开微信登录页</h2><p>正在准备应用内安全网页环境。</p></div></section>';
    } else if (state === 'error') {
      body = '<section class="reference-wechat-login-error"><div><span class="reference-symbol" aria-hidden="true">!</span><h2>无法打开微信登录页</h2><p>请检查网络连接和 WebView 运行时后重试；当前没有写入新的认证信息。</p><button type="button">重新打开登录页</button></div></section>';
    } else {
      const handoff = state === 'content'
        ? handoffMarkup('is-success', '登录成功，连接信息已保存在本机；返回后将刷新公众号内容。')
        : state === 'partial-error'
        ? handoffMarkup('is-error', '候选认证校验失败，已恢复原连接；可刷新二维码后重新扫码。')
        : state === 'operation-locked'
        ? handoffMarkup('is-warn', '正在提取、保存并校验认证信息；完成前暂不能返回或重复操作。')
        : state === 'external-error'
        ? handoffMarkup('is-error', '系统浏览器未能打开微信登录页；应用内扫码页和当前位置均已保留。')
        : handoffMarkup('', '请使用拥有公众号的微信账号扫码；连接信息只在校验通过后保存到本机。');
      body = `${handoff}${documentMarkup()}`;
    }
    const confirmation = state === 'external-confirmation'
      ? '<div class="reference-modal-scrim"><section class="reference-card reference-modal" role="dialog" aria-modal="true" aria-labelledby="reference-wechat-login-external-title" data-reference-modal><h2 id="reference-wechat-login-external-title">在系统浏览器打开微信登录页？</h2><p>系统浏览器不与应用内登录页共享认证结果。若要连接本应用，仍需回到这里完成扫码。</p><div><button type="button" data-reference-modal-cancel>取消</button><button class="reference-demo-primary" type="button">继续打开</button></div></section></div>'
      : '';
    return `<section class="reference-wechat-login">${toolbarMarkup(state)}<div class="reference-wechat-login-body">${body}</div>${confirmation}</section>`;
  }

  window.qingyuanWechatLoginReference = {render};
})();
