import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/debounce_config.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import '../sessions/active_session_provider.dart';

const String _kStageDurationsRequestId = 'stage_durations';

/// 已確認的設定（用於 API 呼叫，debounce 後才更新）
class _CommittedConfigNotifier extends Notifier<StageDurationsConfig> {
  @override
  StageDurationsConfig build() => const StageDurationsConfig();

  void update(StageDurationsConfig config) => state = config;
}

final _committedStageDurationsConfigProvider =
    NotifierProvider<_CommittedConfigNotifier, StageDurationsConfig>(
      _CommittedConfigNotifier.new,
    );

/// 管理步態分期設定狀態的 Notifier，加入 debounce 機制。
class StageDurationsConfigNotifier extends Notifier<StageDurationsConfig> {
  Timer? _debounceTimer;

  @override
  StageDurationsConfig build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const StageDurationsConfig();
  }

  void _updateWithDebounce(StageDurationsConfig Function() updater) {
    final newState = updater();
    if (state == newState) {
      return;
    }
    // UI 設定立即更新
    state = newState;

    // 延遲更新已確認設定（供 API 使用）
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kConfigDebounceDuration, () {
      ref.read(_committedStageDurationsConfigProvider.notifier).update(state);
    });
  }

  void updateProjection(String value) {
    if (state.projection == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(projection: value));
  }

  void updateSmoothWindow(int value) {
    if (state.smoothWindow == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(smoothWindow: value));
  }

  void updateMinVAbs(double value) {
    if ((state.minVAbs - value).abs() < 1e-6) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(minVAbs: value));
  }

  void updateFlatFrac(double value) {
    if ((state.flatFrac - value).abs() < 1e-6) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(flatFrac: value));
  }

  void reset() {
    _debounceTimer?.cancel();
    state = const StageDurationsConfig();
    // reset 時立即更新已確認設定
    ref.read(_committedStageDurationsConfigProvider.notifier).update(state);
  }
}

/// 提供 UI 使用的步態分期設定 Provider。
final stageDurationsConfigProvider =
    NotifierProvider<StageDurationsConfigNotifier, StageDurationsConfig>(
      StageDurationsConfigNotifier.new,
    );

/// 依據目前 session 與設定取得步態分期資料。
/// 使用已確認設定實現真正的 debounce。
final stageDurationsProvider =
    FutureProvider.autoDispose<StageDurationsResponse>((ref) async {
      final sessionName = ref.watch(activeSessionProvider).trim();
      if (sessionName.isEmpty) {
        ref.read(requestFailureStoreProvider.notifier).clearFailure(
              _kStageDurationsRequestId,
            );
        return StageDurationsResponse.empty;
      }
      // 監聽已確認設定，只有 debounce 後才會觸發 API
      final config = ref.watch(_committedStageDurationsConfigProvider);
      final repository = ref.watch(dashboardRepositoryProvider);
      final fingerprint = Object.hash(sessionName, config.toJson().toString());
      return fetchWithFailureGate(
        ref,
        requestId: _kStageDurationsRequestId,
        fingerprint: fingerprint,
        fetch: () => repository.fetchStageDurations(
          sessionName: sessionName,
          config: config,
        ),
      );
    });

/// 從原始資料計算統計分析結果。
final stageDurationsAnalyticsProvider = Provider<StageDurationsAnalytics?>((
  ref,
) {
  final asyncValue = ref.watch(stageDurationsProvider);
  return asyncValue.maybeWhen(
    data: (data) {
      if (data.laps.isEmpty) {
        return null;
      }
      return computeAnalytics(data);
    },
    orElse: () => null,
  );
});
