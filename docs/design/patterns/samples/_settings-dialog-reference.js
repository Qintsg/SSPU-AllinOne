/*
 * 设置任务模态参考渲染 — 密码、微信配置与数据删除边界
 * @Project : SSPU-AllinOne
 * @File : _settings-dialog-reference.js
 * @Author : Qintsg
 * @Date : 2026-08-18
 */

(() => {
  'use strict';

  /**
   * 渲染设置任务的确定性进度账本。
   *
   * :param entry: 当前视觉目录条目。
   * :param state: 当前冻结状态。
   * :param copyFor: 状态文案解析函数。
   * :returns: 匹配时返回设置任务 HTML，否则返回 null。
   */
  function renderSettingsTask(entry, state, copyFor) {
    const id = entry.id;
    if (!['settings.data-privacy', 'settings.update', 'settings.wechat-auth'].includes(id)) return null;
    if (id === 'settings.wechat-auth' && state === 'initial') return null;
    const loading = state === 'loading';
    const error = state === 'error';
    const rows = id === 'settings.data-privacy'
      ? [
          ['清除校园缓存', error ? '结果已保留' : loading ? '保留当前设置' : '当前设置', error ? '查看' : loading ? '处理中' : '清除'],
          ['断开账户连接', error ? '可安全重试' : loading ? '保留当前设置' : '保存在本机', error ? '重试' : loading ? '处理中' : '断开'],
          ['查看隐私说明', error ? '可安全重试' : loading ? '保留当前设置' : '保存在本机', error ? '重试' : loading ? '处理中' : '查看'],
        ]
      : id === 'settings.update'
      ? [
          ['当前版本 1.0.0', error ? '结果已保留' : loading ? '保留当前设置' : '当前设置', error ? '查看' : loading ? '处理中' : null],
          ['更新通道 stable', error ? '可安全重试' : loading ? '保留当前设置' : '只在手动检查时联网', error ? '重试' : loading ? '处理中' : '切换'],
          ['自动检查已关闭', loading ? '保留当前设置' : '启动时不自动访问 GitHub', loading ? '处理中' : null],
        ]
      : [
          ['生成登录二维码', error ? '结果已保留' : loading ? '保留当前设置' : '当前设置', error ? '重新认证' : loading ? '处理中' : '重新认证'],
          ['等待手机确认', error ? '可安全重试' : loading ? '保留当前设置' : '保存在本机', error ? '重新认证' : loading ? '处理中' : '重新认证'],
          ['连接后只读取授权信息', error ? '可安全重试' : loading ? '保留当前设置' : '保存在本机', error ? '重新校验' : loading ? '处理中' : '重新校验'],
        ];
    const prefix = error ? ['已完成：', '未完成：', '未完成：'] : ['', '', ''];
    const banner = loading
      ? `<div class="reference-banner is-warn reference-settings-status">${copyFor(entry, state)[1]}</div>`
      : error
      ? `<div class="reference-banner is-error reference-settings-status">${copyFor(entry, state)[1]}</div>`
      : '';
    const ledger = rows.map((row, index) => `<div class="reference-setting-row"><span><strong>${prefix[index]}${row[0]}</strong><small>${row[1]}</small></span>${row[2] ? `<button type="button"${loading ? ' disabled' : ''}>${row[2]}</button>` : ''}</div>`).join('');
    const result = id === 'settings.update' && state === 'content'
      ? '<div class="reference-settings-result"><span><strong>当前已是正式版最新版本。</strong><small>当前版本：1.0.0</small></span></div>'
      : '';
    return `<section class="reference-card reference-settings-list">${banner}${ledger}${result}</section>`;
  }

  /**
   * 渲染密码或微信配置任务模态。
   *
   * :param entry: 当前视觉目录条目。
   * :param state: 当前冻结状态。
   * :param shellMarkup: 应用壳渲染函数。
   * :returns: 匹配时返回模态 HTML，否则返回 null。
   */
  function renderTask(entry, state, shellMarkup) {
    if (!['security.password-dialog', 'settings.wechat-config'].includes(entry.id)) return null;
    const validationError = state === 'validation-error';
    const password = entry.id === 'security.password-dialog';
    const titleId = password ? 'reference-password-dialog-title' : 'reference-wechat-config-title';
    const fields = password
      ? [
          ['输入密码', 'password', '••••••••', null],
          ['确认密码', 'password', '••••••', validationError ? '两次输入的密码不一致' : null],
        ]
      : [
          ['Cookie', 'text', '已保存在本机', null],
          ['Token', 'text', '123456789', null],
          ['App ID', 'text', 'wx-campus-demo', null],
          ['User-Agent', 'text', 'SSPU-AllinOne/1.0', null],
          ['单次抓取数量', 'text', validationError ? '0' : '10', validationError ? '范围为 1–20' : null],
          ['请求间隔（毫秒）', 'text', '1000', null],
        ];
    const renderField = ([label, type, value, error]) => `<label class="reference-task-field${error ? ' is-error' : ''}"><span>${label}</span><input type="${type}" value="${value}" aria-invalid="${Boolean(error)}" />${error ? `<small>${error}</small>` : ''}</label>`;
    const fieldMarkup = password
      ? fields.map(renderField).join('')
      : `${fields.slice(0, 4).map(renderField).join('')}<div class="reference-task-limit-row">${fields.slice(4).map(renderField).join('')}</div>`;
    const eyebrow = password ? '本机安全' : '高级认证配置';
    const title = password ? '设置本地密码' : '编辑公众号平台配置';
    const message = password
      ? '设置后，每次重新打开应用都需要在本机验证。'
      : '敏感认证信息只保存在本机；请求限制用于降低远端服务压力。';
    return `${shellMarkup('设置')}<div class="reference-task-scrim"></div><section class="reference-task-dialog${password ? '' : ' is-wide'}" role="dialog" aria-modal="true" aria-labelledby="${titleId}"><header><p class="reference-eyebrow">${eyebrow}</p><h2 id="${titleId}">${title}</h2><p>${message}</p></header><div class="reference-task-fields">${fieldMarkup}</div><footer><button type="button">取消</button><button class="reference-demo-primary" type="button">${password ? '设置密码' : '保存配置'}</button></footer></section>`;
  }

  /**
   * 渲染数据与隐私危险确认的删除/保留账本。
   *
   * :param entry: 当前视觉目录条目。
   * :param state: 当前冻结状态。
   * :param shellMarkup: 应用壳渲染函数。
   * :returns: 匹配时返回危险确认 HTML，否则返回 null。
   */
  function renderDataConfirmation(entry, state, shellMarkup) {
    if (!entry.id.startsWith('settings.confirm-') || state !== 'content') return null;
    const content = {
      'settings.confirm-clear-cache': {
        title: '清除校园缓存？',
        deleting: '教务、课表、校园卡、体育、第二课堂、学校邮箱和信息中心的本地缓存。',
        retained: '账户凭据、主题、通知、首页设置和关注列表。',
        note: '只清理本机缓存；校园服务器上的数据不受影响。',
        action: '清除校园缓存',
      },
      'settings.confirm-disconnect-accounts': {
        title: '断开账户连接？',
        deleting: 'OA、体育与邮箱凭据和登录会话、账户关联的校园缓存、微信公众号 Cookie 与 Token。',
        retained: '主题、通知、首页设置、关注列表和信息中心缓存。',
        note: '断开后可重新连接；不会删除校园或公众号平台账号。',
        action: '断开连接',
      },
      'settings.confirm-clear-all-data': {
        title: '清除全部本地数据？',
        deleting: '全部校园凭据、微信连接、校园与信息缓存，以及主题、通知、首页和关注设置。',
        retained: '系统账户、设备生物识别信息和校园服务器上的数据。',
        note: '清除完成后应用会退出。',
        action: '清除本地数据',
      },
    }[entry.id];
    if (!content) return null;
    return `${shellMarkup('设置')}<div class="reference-task-scrim"></div><section class="reference-task-dialog reference-data-confirmation" role="dialog" aria-modal="true" aria-labelledby="reference-data-confirmation-title" data-reference-modal><header><p class="reference-eyebrow">数据与隐私</p><h2 id="reference-data-confirmation-title">${content.title}</h2><p>请先确认本机数据边界；此操作不会修改校园服务器数据。</p></header><div class="reference-data-scope"><section class="is-danger"><span aria-hidden="true">×</span><div><strong>将删除</strong><p>${content.deleting}</p></div></section><section class="is-retained"><span aria-hidden="true">✓</span><div><strong>${entry.id === 'settings.confirm-clear-all-data' ? '不会删除' : '仍会保留'}</strong><p>${content.retained}</p></div></section></div><p class="reference-data-consequence">${content.note}</p><footer><button type="button" data-reference-modal-cancel>取消</button><button class="is-danger" type="button">${content.action}</button></footer></section>`;
  }

  window.qingyuanSettingsDialogReference = {
    renderSettingsTask,
    renderTask,
    renderDataConfirmation,
  };
})();
