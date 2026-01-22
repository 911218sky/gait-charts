import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/debounce_config.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import '../sessions/active_session_provider.dart';

const String _kSpeedHeatmapRequestId = 'speed_heatmap';

/// 速度熱圖色階（純前端視覺化用，不影響 API）。
class SpeedHeatmapColorRange {
  const SpeedHeatmapColorRange({this.vmin = 0.0, this.vmax = 2.0});

  /// 顏色下限 (m/s)。為 null 表示 Auto（依資料自動計算）。
  final double? vmin;

  /// 顏色上限 (m/s)。為 null 表示 Auto（依資料自動計算）。
  final double? vmax;

  SpeedHeatmapColorRange copyWith({
    double? vmin,
    double? vmax,
    bool clear = false,
  }) {
    if (clear) {
      return const SpeedHeatmapColorRange(vmin: null, vmax: null);
    }
    return SpeedHeatmapColorRange(
      vmin: vmin ?? this.vmin,
      vmax: vmax ?? this.vmax,
    );
  }
}

class SpeedHeatmapColorRangeNotifier extends Notifier<SpeedHeatmapColorRange> {
  @override
  SpeedHeatmapColorRange build() => const SpeedHeatmapColorRange();

  void updateVmin(double? value) {
    if (_roughlyEqualNullable(state.vmin, value)) return;
    state = state.copyWith(vmin: value);
  }

  void updateVmax(double? value) {
    if (_roughlyEqualNullable(state.vmax, value)) return;
    state = state.copyWith(vmax: value);
  }

  void useAutoRange() {
    if (state.vmin == null && state.vmax == null) return;
    state = state.copyWith(clear: true);
  }

  void reset() => state = const SpeedHeatmapColorRange();
}

final speedHeatmapColorRangeProvider =
    NotifierProvider<SpeedHeatmapColorRangeNotifier, SpeedHeatmapColorRange>(
      SpeedHeatmapColorRangeNotifier.new,
    );

/// 已確認的設定（用於 API 呼叫，debounce 後才更新）
class _CommittedSpeedHeatmapConfigNotifier
    extends Notifier<SpeedHeatmapConfig> {
  @override
  SpeedHeatmapConfig build() => const SpeedHeatmapConfig();

  void update(SpeedHeatmapConfig config) => state = config;
}

final _committedSpeedHeatmapConfigProvider =
    NotifierProvider<_CommittedSpeedHeatmapConfigNotifier, SpeedHeatmapConfig>(
      _CommittedSpeedHeatmapConfigNotifier.new,
    );

/// 管理 speed_heatmap 設定的 Notifier，加入 debounce 機制。
class SpeedHeatmapConfigNotifier extends Notifier<SpeedHeatmapConfig> {
  Timer? _debounceTimer;

  @override
  SpeedHeatmapConfig build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const SpeedHeatmapConfig();
  }

  void _updateWithDebounce(SpeedHeatmapConfig Function() updater) {
    final newState = updater();
    if (state == newState) {
      return;
    }
    // UI 設定立即更新
    state = newState;

    // 延遲更新已確認設定（供 API 使用）
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kConfigDebounceDuration, () {
      ref.read(_committedSpeedHeatmapConfigProvider.notifier).update(state);
    });
  }

  void updateProjection(String value) {
    if (state.projection == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(projection: value));
  }

  void updateSmoothWindow(int value) {
    final clamped = value.clamp(1, 30);
    if (state.smoothWindow == clamped) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(smoothWindow: clamped));
  }

  void updateMinVAbs(double value) {
    final clamped = value.clamp(1.0, 80.0);
    if (_roughlyEqual(state.minVAbs, clamped)) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(minVAbs: clamped));
  }

  void updateFlatFrac(double value) {
    final clamped = value.clamp(0.1, 1.2);
    if (_roughlyEqual(state.flatFrac, clamped)) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(flatFrac: clamped));
  }

  void updateWidth(int value) {
    final clamped = value.clamp(50, 800);
    if (state.width == clamped) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(width: clamped));
  }

  void reset() {
    _debounceTimer?.cancel();
    state = const SpeedHeatmapConfig();
    // reset 時立即更新已確認設定
    ref.read(_committedSpeedHeatmapConfigProvider.notifier).update(state);
  }
}

/// 提供 speed_heatmap 設定（UI 用）。
final speedHeatmapConfigProvider =
    NotifierProvider<SpeedHeatmapConfigNotifier, SpeedHeatmapConfig>(
      SpeedHeatmapConfigNotifier.new,
    );

/// 取得速度熱圖資料，使用已確認設定以便 debounce。
final speedHeatmapProvider = FutureProvider<SpeedHeatmapResponse>((ref) async {
  final sessionName = ref.watch(activeSessionProvider).trim();
  if (sessionName.isEmpty) {
    ref.read(requestFailureStoreProvider.notifier).clearFailure(
          _kSpeedHeatmapRequestId,
        );
    return SpeedHeatmapResponse.empty;
  }
  final config = ref.watch(_committedSpeedHeatmapConfigProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  final fingerprint = Object.hash(sessionName, config.toJson().toString());
  return fetchWithFailureGate(
    ref,
    requestId: _kSpeedHeatmapRequestId,
    fingerprint: fingerprint,
    fetch: () =>
        repository.fetchSpeedHeatmap(sessionName: sessionName, config: config),
  );
});

/// 判斷兩個 double 是否在容許範圍內相等。
bool _roughlyEqual(double a, double b, {double tolerance = 1e-3}) =>
    (a - b).abs() < tolerance;

bool _roughlyEqualNullable(double? a, double? b, {double tolerance = 1e-3}) {
  if (a == null && b == null) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  return _roughlyEqual(a, b, tolerance: tolerance);
}
