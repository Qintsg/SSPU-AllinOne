/*
 * 微信公众号登录认证事务 — Cookie 候选保存、校验与安全回滚
 * @Project : SSPU-AllinOne
 * @File : wxmp_login_auth_transaction.dart
 * @Author : Qintsg
 * @Date : 2026-08-19
 */

part of 'wxmp_login_page.dart';

/// 承载登录凭据候选事务，确保页面换代时不写入过期结果。
extension _WxmpLoginAuthTransaction on _WxmpLoginPageState {
  /// 提取 Cookie、保存候选认证并在校验失败时恢复原连接。
  ///
  /// :param token: 登录成功页面识别出的公众号 Token。
  /// :param successUrl: 当前登录成功 URL，供 Cookie 读取器补齐作用域。
  /// :param generation: WebView 回调创建时的页面换代号。
  /// :param controller: 当前换代绑定的 WebView 控制器。
  /// :returns: 认证完成、失败回滚或页面换代丢弃后结束。
  Future<void> _extractCookieAndSave(
    String token,
    String successUrl, {
    required int generation,
    required InAppWebViewController controller,
  }) async {
    if (!_isCurrentDocument(generation, controller) || _extracting) return;
    _setLoginState(() => _extracting = true);

    final authService = WxmpAuthService.instance;
    WxmpAuthSnapshot? previousAuth;
    var candidateWriteStarted = false;
    try {
      final captureAuth =
          widget.testOverrides?.captureAuth ?? authService.captureAuth;
      previousAuth = await captureAuth();
      if (!_isCurrentDocument(generation, controller)) return;
      WxmpCookieReadResult? lastCookieReadResult;
      WxmpAuthValidationResult? lastValidation;

      for (var attempt = 0; attempt < 4; attempt++) {
        await Future.delayed(Duration(milliseconds: 500 + attempt * 500));
        if (!_isCurrentDocument(generation, controller)) return;
        final readCookies =
            widget.testOverrides?.readCookies ?? readWxmpCookies;
        lastCookieReadResult = await readCookies(
          successUrl: successUrl,
          controller: controller,
          webViewEnvironment: widget.webViewEnvironment,
        );
        if (!_isCurrentDocument(generation, controller)) return;
        if (lastCookieReadResult.cookieMap.isEmpty) continue;

        final cookieStr = lastCookieReadResult.cookieMap.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('; ');

        candidateWriteStarted = true;
        final saveAuth = widget.testOverrides?.saveAuth;
        if (saveAuth != null) {
          await saveAuth(cookieStr, token);
        } else {
          await authService.saveAuth(cookieStr, token);
        }
        if (!_isCurrentDocument(generation, controller)) {
          await _restorePreviousAuth(
            authService,
            previousAuth,
            candidateWriteStarted: candidateWriteStarted,
          );
          return;
        }
        final validateAuth =
            widget.testOverrides?.validateAuth ??
            WxmpArticleService.instance.validateAuth;
        lastValidation = await validateAuth();
        if (!_isCurrentDocument(generation, controller)) {
          await _restorePreviousAuth(
            authService,
            previousAuth,
            candidateWriteStarted: candidateWriteStarted,
          );
          return;
        }
        if (lastValidation.isValid) {
          debugPrint(
            '[WxmpLogin] 认证保存成功, Cookie 数量: '
            '${lastCookieReadResult.cookieMap.length}, Cookie 键名: '
            '${lastCookieReadResult.cookieNames.toList()..sort()}',
          );
          _setLoginState(() {
            _extracting = false;
            _initFailed = false;
            _failureKind = null;
            _title = '登录已完成';
            _result = _LoginResult(
              success: true,
              message: '登录成功，Token 和 Cookie 已保存',
            );
          });
          return;
        }
      }

      final cookieCount = lastCookieReadResult?.cookieMap.length ?? 0;
      final cookieNames = lastCookieReadResult?.cookieNames ?? <String>{};
      if (cookieCount == 0) {
        final restoreMessage = await _restorePreviousAuth(
          authService,
          previousAuth,
          candidateWriteStarted: candidateWriteStarted,
        );
        if (_isCurrentDocument(generation, controller)) {
          _setLoginState(() {
            _extracting = false;
            _failureKind = _LoginFailureKind.candidateValidation;
            _result = _LoginResult(
              success: false,
              message: candidateWriteStarted
                  ? '未再次获取到 Cookie；$restoreMessage。请重新扫码后重试。'
                  : '未获取到 Cookie；$restoreMessage。请确认已完成扫码后重试。',
            );
          });
        }
        return;
      }

      debugPrint(
        '[WxmpLogin] 认证保存后校验失败: ${lastValidation?.message}, Cookie 数量: $cookieCount, Cookie 键名: '
        '${cookieNames.toList()..sort()}',
      );
      final restoreMessage = await _restorePreviousAuth(
        authService,
        previousAuth,
        candidateWriteStarted: candidateWriteStarted,
      );
      if (_isCurrentDocument(generation, controller)) {
        _setLoginState(() {
          _extracting = false;
          _failureKind = _LoginFailureKind.candidateValidation;
          _result = _LoginResult(
            success: false,
            message:
                '认证校验失败：${lastValidation?.message ?? 'Cookie 不完整'}；$restoreMessage',
          );
        });
      }
    } catch (error) {
      final restoreMessage = await _restorePreviousAuth(
        authService,
        previousAuth,
        candidateWriteStarted: candidateWriteStarted,
      );
      if (_isCurrentDocument(generation, controller)) {
        _setLoginState(() {
          _extracting = false;
          _failureKind = _LoginFailureKind.candidateValidation;
          _result = _LoginResult(
            success: false,
            message: '提取失败：$error；$restoreMessage',
          );
        });
      }
    }
  }

  /// 恢复保存候选认证前的本机连接快照。
  ///
  /// :param authService: 默认认证存储服务。
  /// :param snapshot: 写入候选认证前的快照。
  /// :param candidateWriteStarted: 是否确实写入过候选认证。
  /// :returns: 可直接展示给用户的恢复结果说明。
  Future<String> _restorePreviousAuth(
    WxmpAuthService authService,
    WxmpAuthSnapshot? snapshot, {
    required bool candidateWriteStarted,
  }) async {
    if (!candidateWriteStarted) return '没有写入新的认证信息';
    if (snapshot == null) return '无法确认原连接状态';
    try {
      final restoreAuth = widget.testOverrides?.restoreAuth;
      if (restoreAuth != null) {
        await restoreAuth(snapshot);
      } else {
        await authService.restoreAuth(snapshot);
      }
      final hadPreviousAuth =
          (snapshot.cookie?.trim().isNotEmpty ?? false) &&
          (snapshot.token?.trim().isNotEmpty ?? false);
      return hadPreviousAuth ? '已恢复原连接' : '未保留无效候选凭据';
    } catch (error) {
      debugPrint('[WxmpLogin] 原认证恢复失败: $error');
      return '原连接恢复失败，请返回认证设置检查状态';
    }
  }
}
