import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/debounce_config.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import '../sessions/active_session_provider.dart';

const String _kPerLapOffsetRequestId = 'per_lap_offset';

/// 已確認的設定（用於 API 呼叫，debounce 後才更新）
class _CommittedConfigNotifier extends Notifier<PerLapOffsetConfig> {
  @override
  PerLapOffsetConfig build() => const PerLapOffsetConfig();

  void update(PerLapOffsetConfig config) => state = config;
}

final _committedPerLapOffsetConfigProvider =
    NotifierProvider<_CommittedConfigNotifier, PerLapOffsetConfig>(
      _CommittedConfigNotifier.new,
    );

/// 管理 per-lap offset 設定的 Notifier，加入 debounce 機制。
class PerLapOffsetConfigNotifier extends Notifier<PerLapOffsetConfig> {
  Timer? _debounceTimer;

  @override
  PerLapOffsetConfig build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const PerLapOffsetConfig();
  }

  void _updateWithDebounce(PerLapOffsetConfig Function() updater) {
    final newState = updater();
    if (state == newState) {
      return;
    }
    // UI 設定立即更新
    state = newState;

    // 延遲更新已確認設定（供 API 使用）
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kConfigDebounceDuration, () {
      ref.read(_committedPerLapOffsetConfigProvider.notifier).update(state);
    });
  }

  void updateProjection(String value) {
    if (state.projection == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(projection: value));
  }

  void updateSmoothWindowSeconds(double value) {
    if (_roughlyEqual(state.smoothWindowSeconds, value)) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(smoothWindowSeconds: value));
  }

  void updateMinVAbs(double value) {
    if (_roughlyEqual(state.minVAbs, value)) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(minVAbs: value));
  }

  void updateFlatFrac(double value) {
    if (_roughlyEqual(state.flatFrac, value)) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(flatFrac: value));
  }

  void updateKSmooth(int value) {
    if (state.kSmooth == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(kSmooth: value));
  }

  void reset() {
    _debounceTimer?.cancel();
    state = const PerLapOffsetConfig();
    // reset 時立即更新已確認設定
    ref.read(_committedPerLapOffsetConfigProvider.notifier).update(state);
  }
}

/// 提供 per-lap offset 設定的 Provider。
final perLapOffsetConfigProvider =
    NotifierProvider<PerLapOffsetConfigNotifier, PerLapOffsetConfig>(
      PerLapOffsetConfigNotifier.new,
    );

/// 取得 per-lap offset 分析資料，使用已確認設定實現真正的 debounce。
final perLapOffsetProvider = FutureProvider<PerLapOffsetResponse>((ref) async {
  final sessionName = ref.watch(activeSessionProvider).trim();
  if (sessionName.isEmpty) {
    ref.read(requestFailureStoreProvider.notifier).clearFailure(
          _kPerLapOffsetRequestId,
        );
    return PerLapOffsetResponse.empty;
  }
  // 監聽已確認設定，只有 debounce 後才會觸發 API
  final config = ref.watch(_committedPerLapOffsetConfigProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  final fingerprint = Object.hash(sessionName, config.toJson().toString());
  return fetchWithFailureGate(
    ref,
    requestId: _kPerLapOffsetRequestId,
    fingerprint: fingerprint,
    fetch: () =>
        repository.fetchPerLapOffset(sessionName: sessionName, config: config),
  );
});

/// 紀錄目前選取的 per-lap 圈數。
final perLapOffsetSelectedLapProvider =
    NotifierProvider<PerLapOffsetSelectedLapNotifier, int?>(
      PerLapOffsetSelectedLapNotifier.new,
    );

/// 控制偏移畫面圈數選取的 Notifier。
class PerLapOffsetSelectedLapNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? lapIndex) {
    state = lapIndex;
  }
}

/// 判斷兩個 double 是否在容許範圍內相等。
bool _roughlyEqual(double a, double b, {double tolerance = 1e-3}) =>
    (a - b).abs() < tolerance;
