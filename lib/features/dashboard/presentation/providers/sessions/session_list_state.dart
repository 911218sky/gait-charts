import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/realsense_session.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';

/// 管理 session 清單分頁狀態的資料類型。
@immutable
class SessionListState {
  const SessionListState({
    this.items = const [],
    this.page = 0,
    this.totalPages = 0,
    this.isLoading = false,
    this.error,
    this.initialized = false,
    this.pageSize = 20,
    this.deletingSessions = const {},
    this.userFilter,
    this.excludeUserCode,
  });

  final List<RealsenseSessionItem> items;
  final int page;
  final int totalPages;
  final bool isLoading;
  final Object? error;
  final bool initialized;
  final int pageSize;
  final Set<String> deletingSessions;

  /// 若不為空，代表目前列表是「依使用者」載入的 sessions。
  final UserListItem? userFilter;

  /// 若不為空，代表目前列表會排除指定 user_code 的 sessions（常用於「綁定」時避免出現已綁定的項目）。
  final String? excludeUserCode;

  bool get isInitialLoading => isLoading && items.isEmpty;

  bool get canLoadMore => page < totalPages;

  bool isDeleting(String sessionName) => deletingSessions.contains(sessionName);

  bool get isUserFiltered => userFilter != null;

  bool get isExcludeUserCodeFiltered =>
      (excludeUserCode ?? '').trim().isNotEmpty;

  SessionListState copyWith({
    List<RealsenseSessionItem>? items,
    int? page,
    int? totalPages,
    bool? isLoading,
    Object? error = _sentinelError,
    bool? initialized,
    int? pageSize,
    Set<String>? deletingSessions,
    UserListItem? userFilter,
    bool clearUserFilter = false,
    String? excludeUserCode,
    bool clearExcludeUserCode = false,
  }) {
    return SessionListState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinelError) ? this.error : error,
      initialized: initialized ?? this.initialized,
      pageSize: pageSize ?? this.pageSize,
      deletingSessions: deletingSessions ?? this.deletingSessions,
      userFilter: clearUserFilter ? null : userFilter ?? this.userFilter,
      excludeUserCode:
          clearExcludeUserCode ? null : excludeUserCode ?? this.excludeUserCode,
    );
  }
}

/// 控制 session 清單抓取 / 加載更多的 Notifier。
class SessionListNotifier extends Notifier<SessionListState> {
  DashboardRepository get _repository => ref.watch(dashboardRepositoryProvider);

  @override
  SessionListState build() => const SessionListState();

  Future<void> fetchFirstPage({bool force = false}) async {
    if (state.isLoading && !force) {
      return;
    }

    // 若目前是「依使用者」模式，刷新時應維持該使用者的 sessions。
    final userFilter = state.userFilter;
    if (userFilter != null) {
      await fetchForUser(userFilter, force: true);
      return;
    }

    // 先 snapshot，避免 await 後 provider dispose 時仍去讀 state 造成例外。
    final pageSize = state.pageSize;
    final excludeUserCode = state.excludeUserCode;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.fetchRealsenseSessions(
        page: 1,
        pageSize: pageSize,
        excludeUserCode: excludeUserCode,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        items: response.items,
        page: response.page,
        totalPages: response.totalPages,
        isLoading: false,
        initialized: true,
        error: null,
      );
    } catch (error, _) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, error: error, initialized: true);
    }
  }

  /// 設定排除指定 user_code 的 sessions（常用於「綁定」場景），並重新載入第一頁。
  Future<void> setExcludeUserCodeAndReload(String? excludeUserCode) async {
    final normalized = excludeUserCode?.trim();
    state = state.copyWith(
      items: const [],
      page: 0,
      totalPages: 0,
      isLoading: false,
      error: null,
      initialized: true,
      excludeUserCode: (normalized != null && normalized.isNotEmpty)
          ? normalized
          : null,
      // 排除模式與 userFilter 不可同時使用（後端會擋），因此切換時清掉 userFilter。
      clearUserFilter: true,
    );
    await fetchFirstPage(force: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.canLoadMore) {
      return;
    }
    final nextPage = state.page + 1;
    final pageSize = state.pageSize;
    final userFilter = state.userFilter;
    final excludeUserCode = state.excludeUserCode;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.fetchRealsenseSessions(
        page: nextPage,
        pageSize: pageSize,
        userCode: userFilter?.userCode,
        excludeUserCode: userFilter == null ? excludeUserCode : null,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        items: [...state.items, ...response.items],
        page: response.page,
        totalPages: response.totalPages,
        isLoading: false,
        error: null,
      );
    } catch (error, _) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  /// 明確切換到指定頁（用於具有「頁碼按鈕」的 UI）。
  ///
  /// 設計：以「置換 items」為主，避免同時 append 多頁造成使用者混淆。
  Future<void> goToPage(int targetPage) async {
    if (state.isLoading) {
      return;
    }

    final total = state.totalPages <= 0 ? 1 : state.totalPages;
    final nextPage = targetPage.clamp(1, total);
    if (nextPage == state.page) {
      return;
    }

    final pageSize = state.pageSize;
    final userFilter = state.userFilter;
    final excludeUserCode = state.excludeUserCode;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.fetchRealsenseSessions(
        page: nextPage,
        pageSize: pageSize,
        userCode: userFilter?.userCode,
        excludeUserCode: userFilter == null ? excludeUserCode : null,
      );
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        items: response.items,
        page: response.page,
        totalPages: response.totalPages,
        isLoading: false,
        error: null,
        initialized: true,
      );
    } catch (error, _) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, error: error, initialized: true);
    }
  }

  /// 以「使用者」作為來源載入 sessions（一次載入該使用者所有 sessions/bag）。
  Future<void> fetchForUser(UserListItem user, {bool force = false}) async {
    if (state.isLoading && !force) {
      return;
    }
    final code = user.userCode.trim();
    if (code.isEmpty) {
      return;
    }

    final pageSize = state.pageSize;
    state = state.copyWith(
      isLoading: true,
      error: null,
      userFilter: user,
      initialized: true,
      clearExcludeUserCode: true,
    );

    try {
      final response = await _repository.fetchRealsenseSessions(
        page: 1,
        pageSize: pageSize,
        userCode: code,
      );
      if (!ref.mounted) {
        return;
      }

      state = state.copyWith(
        items: response.items,
        page: response.page,
        totalPages: response.totalPages,
        isLoading: false,
        error: null,
        initialized: true,
      );
    } catch (error, _) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: error,
        initialized: true,
      );
    }
  }

  /// 清除「依使用者」篩選，回到全域 sessions 分頁列表。
  Future<void> clearUserFilterAndReload() async {
    state = state.copyWith(
      items: const [],
      page: 0,
      totalPages: 0,
      isLoading: false,
      error: null,
      initialized: true,
      clearUserFilter: true,
      // 回到全域列表時也一併清掉排除條件（避免使用者誤以為漏資料）。
      clearExcludeUserCode: true,
    );
    await fetchFirstPage(force: true);
  }

  /// 刪除指定 session，並在成功後從目前列表移除。
  ///
  /// 注意：為避免 UI 觸發大量重載，這裡採用「就地移除」的方式；
  /// 使用者仍可透過 Session Picker 的「重新整理」按鈕重新同步分頁資訊。
  Future<DeleteSessionResponse?> deleteSession({
    required String sessionName,
  }) async {
    final normalized = sessionName.trim();
    if (normalized.isEmpty || state.isDeleting(normalized)) {
      return null;
    }

    final nextDeleting = {...state.deletingSessions, normalized};
    state = state.copyWith(deletingSessions: nextDeleting, error: null);
    try {
      final response = await _repository.deleteRealsenseSession(
        sessionName: normalized,
      );
      if (!ref.mounted) {
        return response;
      }

      final remaining = state.items
          .where((item) => item.sessionName != normalized)
          .toList(growable: false);
      final updatedDeleting = {...state.deletingSessions}..remove(normalized);
      state = state.copyWith(items: remaining, deletingSessions: updatedDeleting);
      return response;
    } catch (error, _) {
      if (!ref.mounted) {
        rethrow;
      }
      final updatedDeleting = {...state.deletingSessions}..remove(normalized);
      state = state.copyWith(deletingSessions: updatedDeleting, error: error);
      rethrow;
    }
  }

  /// 從目前列表中移除多個 sessions（用於批量刪除後的就地更新）。
  void removeSessions(Iterable<String> sessionNames) {
    final normalized = sessionNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) {
      return;
    }

    final remaining = state.items
        .where((item) => !normalized.contains(item.sessionName))
        .toList(growable: false);
    final updatedDeleting = {...state.deletingSessions}
      ..removeWhere(normalized.contains);
    state = state.copyWith(items: remaining, deletingSessions: updatedDeleting);
  }
}

/// 提供 session 清單狀態的 auto dispose Provider。
final sessionListProvider =
    NotifierProvider.autoDispose<SessionListNotifier, SessionListState>(
      SessionListNotifier.new,
    );

const _sentinelError = Object();
