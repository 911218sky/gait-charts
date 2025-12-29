import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/network/errors/api_exception.dart';
import 'package:gait_charts/features/admin/data/admin_repository.dart';
import 'package:gait_charts/features/admin/domain/models/admin_models.dart';
import 'package:gait_charts/features/admin/presentation/providers/admin_token_provider.dart';

class AdminAuthNotifier extends AsyncNotifier<AuthSession?> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  Future<AuthSession?> build() async {
    // 嘗試從本機還原登入 session
    final session = await _repo.restoreSession();
    _syncToken(session);
    return session;
  }

  /// 登入
  /// 錯誤會往上拋出，由呼叫端 catch 並用 Toast 顯示。
  Future<AuthSession?> login({
    required String username,
    required String password,
  }) async {
    // 不設定 state = AsyncLoading，避免 AdminAuthGate 切換到 loading 畫面
    final session = await _repo.login(username: username, password: password);
    _syncToken(session);
    state = AsyncData(session);
    return session;
  }

  /// 註冊
  /// 錯誤會往上拋出，由呼叫端 catch 並用 Toast 顯示。
  Future<AuthSession?> register({
    required String username,
    required String password,
    String? inviteCode,
  }) async {
    // 不設定 state = AsyncLoading，避免 AdminAuthGate 切換到 loading 畫面
    final session = await _repo.register(
      username: username,
      password: password,
      inviteCode: inviteCode,
    );
    _syncToken(session);
    state = AsyncData(session);
    return session;
  }

  /// 登出
  /// 錯誤會往上拋出，由呼叫端 catch 並用 Toast 顯示。
  Future<void> logout() async {
    final token = currentToken();
    await _repo.logout(token: token);
    // 登出後，清空 token
    _syncToken(null);
    // 登出後，清空 state
    state = const AsyncData(null);
  }

  /// 變更密碼
  /// 錯誤會往上拋出，由呼叫端 catch 並用 Toast 顯示。
  Future<AuthSession?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    // 變更密碼前，先檢查是否登入
    final prevSession = state.asData?.value;
    final token = prevSession?.token;
    if (token == null || token.isEmpty) {
      state = AsyncError('尚未登入，請重新登入', StackTrace.current);
      return null;
    }
    // 變更密碼時，設定 AsyncLoading，讓 UI 顯示處理中（避免使用者以為卡住）。
    state = const AsyncLoading();
    try {
      final session = await _repo.changePassword(
        token: token,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _syncToken(session);
      state = AsyncData(session);
      return session;
    } catch (error, stack) {
      // 保持原本登入狀態
      state = AsyncData(prevSession);
      Error.throwWithStackTrace(error, stack);
    }
  }

  /// 更新目前登入管理員的 username（`PATCH /admins/me`）。
  ///
  /// 注意：刻意不把 `state` 設成 AsyncLoading，避免 `AdminAuthGate` 切到全屏 loading。
  Future<AdminPublic> updateMeUsername(String username) async {
    final current = state.asData?.value;
    final token = current?.token;
    if (current == null || token == null || token.isEmpty) {
      throw ApiException(message: '尚未登入，請重新登入');
    }

    try {
      final updated = await _repo.updateMeUsername(
        token: token,
        username: username,
      );
      state = AsyncData(
        AuthSession(
          token: current.token,
          expiresAt: current.expiresAt,
          admin: updated,
        ),
      );
      return updated;
    } catch (error, stack) {
      // 保持原本登入狀態
      state = AsyncData(current);
      Error.throwWithStackTrace(error, stack);
    }
  }

  String? currentToken() => state.asData?.value?.token;

  // 同步 token 到 adminTokenStateProvider，方便在需要 headers 的地方直接取 token。
  void _syncToken(AuthSession? session) {
    ref.read(adminTokenStateProvider.notifier).setToken(session?.token);
  }
}

final adminAuthProvider =
    AsyncNotifierProvider<AdminAuthNotifier, AuthSession?>(
  AdminAuthNotifier.new,
);

/// 方便在 presentation 層需要 token 的地方直接取；未登入時回傳 null。
///
/// 注意：Dio 的 Authorization 注入是讀 `adminTokenStateProvider`（見 `dioProvider`）。
final adminTokenProvider = Provider<String?>((ref) {
  final auth = ref.watch(adminAuthProvider);
  return auth.maybeWhen(
    data: (session) => session?.token,
    orElse: () => null,
  );
});