/*
 * OA 会话预热服务 — 在应用启动或保存凭据后静默准备可复用登录会话
 * @Project : SSPU-AllinOne
 * @File : academic_oa_session_prewarm_service.dart
 * @Author : Qintsg
 * @Date : 2026-06-04
 */

import '../models/academic_login_validation.dart';
import 'academic_credentials_service.dart';
import 'academic_login_validation_service.dart';

/// 确保本地 OA 会话可用的回调，便于测试中注入 fake。
typedef AcademicOaSessionEnsurer =
    Future<AcademicLoginValidationResult> Function({
      bool forceRefresh,
      bool requireCampusNetwork,
    });

/// 在不阻塞 UI 的情况下静默准备 OA/CAS 登录会话。
class AcademicOaSessionPrewarmService {
  /// 创建可注入依赖的预热服务。
  AcademicOaSessionPrewarmService({
    AcademicCredentialsService? credentialsService,
    AcademicOaSessionEnsurer? ensureSession,
  }) : _credentialsService =
           credentialsService ?? AcademicCredentialsService.instance,
       _ensureSession =
           ensureSession ??
           AcademicLoginValidationService.instance.ensureSavedSession;

  /// 全局单例。
  static final AcademicOaSessionPrewarmService instance =
      AcademicOaSessionPrewarmService();

  final AcademicCredentialsService _credentialsService;
  final AcademicOaSessionEnsurer _ensureSession;

  /// 若本地已保存 OA 账号和密码，则静默确保会话存在。
  Future<AcademicLoginValidationResult?> prewarm({
    bool forceRefresh = true,
    bool requireCampusNetwork = false,
  }) async {
    try {
      final status = await _credentialsService.getStatus();
      if (status.oaAccount.trim().isEmpty || !status.hasOaPassword) {
        return null;
      }
      return await _ensureSession(
        forceRefresh: forceRefresh,
        requireCampusNetwork: requireCampusNetwork,
      );
    } catch (_) {
      // 预热失败不应阻断启动或保存凭据流程；业务页仍会在读取时给出明确状态。
      return null;
    }
  }
}
