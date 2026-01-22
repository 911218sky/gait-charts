import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/debounce_config.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/bag_file.dart';

@immutable
class BagListState {
  const BagListState({
    this.items = const [],
    this.page = 0,
    this.totalPages = 0,
    this.total = 0,
    this.pageSize = 50,
    this.recursive = true,
    this.query = '',
    this.isLoading = false,
    this.initialized = false,
    this.error,
  });

  final List<BagFileItem> items;
  final int page;
  final int totalPages;
  final int total;
  final int pageSize;
  final bool recursive;
  final String query;
  final bool isLoading;
  final bool initialized;
  final Object? error;

  bool get isInitialLoading => isLoading && items.isEmpty;

  BagListState copyWith({
    List<BagFileItem>? items,
    int? page,
    int? totalPages,
    int? total,
    int? pageSize,
    bool? recursive,
    String? query,
    bool? isLoading,
    bool? initialized,
    Object? error = _sentinelError,
  }) {
    return BagListState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      pageSize: pageSize ?? this.pageSize,
      recursive: recursive ?? this.recursive,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      initialized: initialized ?? this.initialized,
      error: identical(error, _sentinelError) ? this.error : error,
    );
  }
}

class BagListNotifier extends Notifier<BagListState> {
  DashboardRepository get _repository => ref.watch(dashboardRepositoryProvider);

  Timer? _debounceTimer;

  @override
  BagListState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _debounceTimer = null;
    });
    return const BagListState();
  }

  String? _normalizedQuery() {
    final q = state.query.trim();
    return q.isEmpty ? null : q;
  }

  /// 設定搜尋關鍵字（server-side search）。
  ///
  /// - `immediate=true`：立刻重新載入（適合 onSubmitted）
  /// - 否則會 debounce 後重新載入（適合 onChanged）
  Future<void> setQuery(String raw, {bool immediate = false}) async {
    final next = raw.trim();
    if (next == state.query) return;

    state = state.copyWith(
      query: next,
      items: const [],
      page: 0,
      totalPages: 0,
      total: 0,
      isLoading: false,
      error: null,
      initialized: true,
    );

    if (immediate) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      await fetchFirstPage(force: true);
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(kConfigDebounceDuration, () {
      // ignore: discarded_futures
      fetchFirstPage(force: true);
    });
  }

  Future<void> fetchFirstPage({bool force = false}) async {
    if (state.isLoading && !force) {
      return;
    }
    final pageSize = state.pageSize;
    final recursive = state.recursive;
    final query = _normalizedQuery();

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.fetchServerBags(
        page: 1,
        pageSize: pageSize,
        recursive: recursive,
        query: query,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        items: response.items,
        page: response.page,
        totalPages: response.totalPages,
        total: response.total,
        isLoading: false,
        initialized: true,
        error: null,
      );
    } catch (error, _) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: error, initialized: true);
    }
  }

  Future<void> goToPage(int targetPage) async {
    if (state.isLoading) return;
    final total = state.totalPages <= 0 ? 1 : state.totalPages;
    final nextPage = targetPage.clamp(1, total);
    if (nextPage == state.page && state.items.isNotEmpty) {
      return;
    }

    final pageSize = state.pageSize;
    final recursive = state.recursive;
    final query = _normalizedQuery();
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.fetchServerBags(
        page: nextPage,
        pageSize: pageSize,
        recursive: recursive,
        query: query,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        items: response.items,
        page: response.page,
        totalPages: response.totalPages,
        total: response.total,
        isLoading: false,
        initialized: true,
        error: null,
      );
    } catch (error, _) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: error, initialized: true);
    }
  }

  Future<void> setRecursiveAndReload(bool recursive) async {
    if (state.recursive == recursive && state.initialized) {
      return;
    }
    state = state.copyWith(
      recursive: recursive,
      items: const [],
      page: 0,
      totalPages: 0,
      total: 0,
      isLoading: false,
      error: null,
      initialized: true,
    );
    await fetchFirstPage(force: true);
  }
}

final bagListProvider = NotifierProvider<BagListNotifier, BagListState>(
  BagListNotifier.new,
);

const Object _sentinelError = Object();


