import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/admin/data/admin_api_service.dart';
import 'package:gait_charts/features/admin/data/admin_auth_storage.dart';
import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:gait_charts/features/admin/domain/models/admin_requests.dart';

@immutable
/// 管理員功能的 Repository（data layer）。
///
/// 職責：
/// - 封裝 `AdminApiService`（HTTP 呼叫）
/// - 封裝 `AdminAuthStorage`（本機 token / expiresAt 的保存與清除）
/// - 以「操作」為單位提供給 presentation layer 使用
class AdminRepository {
  const AdminRepository({
    required this.api,
    required this.storage,
  });

  /// 管理員 API（網路層）。
  final AdminApiService api;

  /// 管理員 token 儲存（本機層）。
  final AdminAuthStorage storage;

  /// 嘗試從本機還原登入 session。
  ///
  /// 流程：
  /// - 先讀取本機 token / expiresAt
  /// - 若存在，呼叫 `/me` 取得管理員資訊
  /// - 若 token 無效或 API 失敗，會清除本機 token，並回傳 null
  Future<AuthSession?> restoreSession() async {
    // 讀取 token 與過期時間
    final stored = await storage.readToken();
    if (stored == null) {
      return null;
    }
    // 取得管理員資訊
    try {
      final me = await api.fetchMe(stored.token);
      return AuthSession(
        token: stored.token,
        expiresAt: stored.expiresAt,
        admin: me,
      );
    } catch (_) {
      // 清除 token 與過期時間
      await storage.clear();
      return null;
    }
  }

  /// 管理員登入。
  ///
  /// 成功後會把 token / expiresAt 寫入本機 storage。
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final session = await api.login(
      LoginRequest(username: username, password: password),
    );
    await storage.saveToken(token: session.token, expiresAt: session.expiresAt);
    return session;
  }

  /// 管理員註冊。
  ///
  /// 成功後會把 token / expiresAt 寫入本機 storage。
  Future<AuthSession> register({
    required String username,
    required String password,
    String? inviteCode,
  }) async {
    final session = await api.register(
      RegisterRequest(
        username: username,
        password: password,
        inviteCode: inviteCode,
      ),
    );
    await storage.saveToken(token: session.token, expiresAt: session.expiresAt);
    return session;
  }

  /// 以指定 token 重新抓取 `/me`（管理員資訊）。
  ///
  /// - 這個方法不會寫入 storage
  /// - 若 API 失敗，回傳 null（由上層決定是否要登出/提示）
  Future<AdminPublic?> refreshMe(String token) async {
    try {
      return await api.fetchMe(token);
    } catch (_) {
      return null;
    }
  }

  /// 登出。
  ///
  /// - 若有 token：會嘗試呼叫登出 API（失敗也不會阻止流程）
  /// - 一定會清除本機 token（避免 UI 卡在「看似已登入」的狀態）
  Future<LogoutResult?> logout({required String? token}) async {
    LogoutResult? result;
    if (token != null && token.isNotEmpty) {
      try {
        result = await api.logout(token);
      } catch (_) {
        // 即使登出 API 失敗，仍會清本機 token，避免卡住。
      }
    }
    await storage.clear();
    return result;
  }

  /// 變更密碼。
  ///
  /// - API 可能回傳新的 session（例如 token 旋轉/延長）
  /// - 成功後會把新的 token / expiresAt 寫入本機 storage
  Future<AuthSession> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final session = await api.changePassword(
      token: token,
      request: ChangePasswordRequest(
        oldPassword: oldPassword,
        newPassword: newPassword,
      ),
    );
    await storage.saveToken(token: session.token, expiresAt: session.expiresAt);
    return session;
  }

  /// 更新目前登入的管理員資訊（目前僅支援 username）。
  Future<AdminPublic> updateMeUsername({
    required String token,
    required String username,
  }) {
    return api.updateMe(
      token: token,
      request: AdminUpdateMeRequest(username: username),
    );
  }

  /// 建立邀請碼（給註冊用）。
  Future<InvitationCode> createInvitation({
    required String token,
    required int expiresInHours,
  }) {
    return api.createInvitation(
      token: token,
      request: InvitationCreateRequest(expiresInHours: expiresInHours),
    );
  }

  /// 取得管理員列表（分頁）。
  Future<AdminListResponse> listAdmins({
    required String token,
    int page = 1,
    int pageSize = 20,
  }) {
    return api.listAdmins(token: token, page: page, pageSize: pageSize);
  }

  /// 刪除指定管理員。
  Future<DeleteAdminResult> deleteAdmin({
    required String token,
    required String adminCode,
  }) {
    return api.deleteAdmin(token: token, adminCode: adminCode);
  }
}

/// 管理員 token 儲存的 provider（預設用真實 storage；測試可覆寫）。
final adminAuthStorageProvider = Provider<AdminAuthStorage>((ref) {
  return AdminAuthStorage();
});

/// 管理員 Repository provider（組合 api + storage）。
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(
    api: ref.watch(adminApiServiceProvider),
    storage: ref.watch(adminAuthStorageProvider),
  );
});
