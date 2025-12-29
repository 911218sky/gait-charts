import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

/// 管理「使用者詳情」載入與操作狀態。
@immutable
class UserDetailState {
  const UserDetailState({
    this.userCode,
    this.detail,
    this.isLoading = false,
    this.isSaving = false,
    this.initialized = false,
    this.error,
  });

  final String? userCode;
  final UserDetailResponse? detail;
  final bool isLoading;
  final bool isSaving;
  final bool initialized;
  final Object? error;

  bool get isInitialLoading => isLoading && detail == null;

  bool get hasDetail => detail != null;

  bool get isBusy => isLoading || isSaving;

  UserDetailState copyWith({
    String? userCode,
    bool clearUserCode = false,
    UserDetailResponse? detail,
    bool clearDetail = false,
    bool? isLoading,
    bool? isSaving,
    bool? initialized,
    Object? error = _sentinelError,
  }) {
    return UserDetailState(
      userCode: clearUserCode ? null : userCode ?? this.userCode,
      detail: clearDetail ? null : detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      initialized: initialized ?? this.initialized,
      error: identical(error, _sentinelError) ? this.error : error,
    );
  }
}

/// 控制使用者載入/建立/更新/綁定 session 的 Notifier。
class UserDetailNotifier extends Notifier<UserDetailState> {
  DashboardRepository get _repository => ref.watch(dashboardRepositoryProvider);

  @override
  UserDetailState build() => const UserDetailState();

  void reset() => state = const UserDetailState();

  Future<void> load(String userCode) async {
    final code = userCode.trim();
    if (code.isEmpty) {
      state = state.copyWith(
        clearUserCode: true,
        clearDetail: true,
        isLoading: false,
        initialized: true,
        error: null,
      );
      return;
    }

    state = state.copyWith(
      userCode: code,
      isLoading: true,
      initialized: true,
      error: null,
    );

    try {
      final detail = await _repository.fetchUserDetail(userCode: code);
      state = state.copyWith(detail: detail, isLoading: false, error: null);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> refresh() async {
    final code = state.userCode?.trim() ?? '';
    if (code.isEmpty) {
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final detail = await _repository.fetchUserDetail(userCode: code);
      state = state.copyWith(detail: detail, isLoading: false, error: null);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<UserItem?> createUser(UserProfileDraft draft) async {
    state = state.copyWith(isSaving: true, error: null, initialized: true);
    try {
      final created = await _repository.createUser(
        request: UserCreateRequest.fromDraft(draft),
      );
      final detail = await _repository.fetchUserDetail(
        userCode: created.userCode,
      );
      state = state.copyWith(
        userCode: created.userCode,
        detail: detail,
        isSaving: false,
        error: null,
      );
      return created;
    } catch (error) {
      state = state.copyWith(isSaving: false, error: error);
      return null;
    }
  }

  /// 更新目前載入的使用者。
  ///
  /// 回傳：
  /// - true：已送出更新
  /// - false：沒有任何欄位變更（不送 request）
  Future<bool> updateCurrentUser(UserProfileDraft next) async {
    final currentDetail = state.detail;
    final userCode = currentDetail?.user.userCode ?? state.userCode;
    if (currentDetail == null || userCode == null || userCode.trim().isEmpty) {
      throw StateError('尚未載入使用者，無法更新');
    }

    final request = UserUpdateRequest.diff(
      original: currentDetail.user,
      next: next,
    );
    if (request.isEmpty) {
      return false;
    }

    state = state.copyWith(isSaving: true, error: null, initialized: true);
    try {
      await _repository.updateUser(userCode: userCode, request: request);
      final detail = await _repository.fetchUserDetail(userCode: userCode);
      state = state.copyWith(detail: detail, isSaving: false, error: null);
      return true;
    } catch (error) {
      state = state.copyWith(isSaving: false, error: error);
      rethrow;
    }
  }

  Future<void> linkSessionToCurrentUser({
    String? sessionName,
    String? bagHash,
  }) async {
    final currentDetail = state.detail;
    final userCode = currentDetail?.user.userCode ?? state.userCode;
    if (userCode == null || userCode.trim().isEmpty) {
      throw StateError('尚未載入使用者，無法綁定 session');
    }

    state = state.copyWith(isSaving: true, error: null, initialized: true);
    try {
      await _repository.linkUserToSession(
        userCode: userCode,
        request: LinkUserSessionRequest(
          sessionName: sessionName,
          bagHash: bagHash,
        ),
      );
      final detail = await _repository.fetchUserDetail(userCode: userCode);
      state = state.copyWith(detail: detail, isSaving: false, error: null);
    } catch (error) {
      state = state.copyWith(isSaving: false, error: error);
      rethrow;
    }
  }

  Future<UnlinkUserSessionResponse> unlinkSessionFromCurrentUser({
    String? sessionName,
    String? bagHash,
    bool unlinkAll = false,
  }) async {
    final currentDetail = state.detail;
    final userCode = currentDetail?.user.userCode ?? state.userCode;
    if (userCode == null || userCode.trim().isEmpty) {
      throw StateError('尚未載入使用者，無法解除綁定 session');
    }

    state = state.copyWith(isSaving: true, error: null, initialized: true);
    try {
      final response = await _repository.unlinkUserFromSession(
        userCode: userCode,
        request: UnlinkUserSessionRequest(
          unlinkAll: unlinkAll,
          sessionName: sessionName,
          bagHash: bagHash,
        ),
      );
      final detail = await _repository.fetchUserDetail(userCode: userCode);
      state = state.copyWith(detail: detail, isSaving: false, error: null);
      return response;
    } catch (error) {
      state = state.copyWith(isSaving: false, error: error);
      rethrow;
    }
  }

  /// 刪除目前載入的使用者。
  ///
  /// - deleteSessions=false：只解除 sessions 綁定並刪 user
  /// - deleteSessions=true：連同 sessions(DB 紀錄) 一併刪除
  Future<DeleteUserResponse> deleteCurrentUser({
    bool deleteSessions = false,
  }) async {
    final currentDetail = state.detail;
    final userCode = currentDetail?.user.userCode ?? state.userCode;
    if (userCode == null || userCode.trim().isEmpty) {
      throw StateError('尚未載入使用者，無法刪除');
    }

    state = state.copyWith(isSaving: true, error: null, initialized: true);
    try {
      final response = await _repository.deleteUser(
        userCode: userCode,
        deleteSessions: deleteSessions,
      );

      // 刪除成功後清空 state（避免 UI 還顯示已刪除的資料）。
      state = const UserDetailState(initialized: true);
      return response;
    } catch (error) {
      state = state.copyWith(isSaving: false, error: error, initialized: true);
      rethrow;
    }
  }
}

final userDetailProvider =
    NotifierProvider<UserDetailNotifier, UserDetailState>(
      UserDetailNotifier.new,
    );

const _sentinelError = Object();
