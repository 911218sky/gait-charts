import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/debounce_config.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import '../sessions/active_session_provider.dart';

const String _kSwingInfoHeatmapRequestId = 'swing_info_heatmap';

/// 已確認的設定（用於 API 呼叫，debounce 後才更新）。
class _CommittedSwingInfoHeatmapConfigNotifier
    extends Notifier<SwingInfoHeatmapConfig> {
  @override
  SwingInfoHeatmapConfig build() => const SwingInfoHeatmapConfig();

  void update(SwingInfoHeatmapConfig config) => state = config;
}

final _committedSwingInfoHeatmapConfigProvider = NotifierProvider<
  _CommittedSwingInfoHeatmapConfigNotifier,
  SwingInfoHeatmapConfig
>(_CommittedSwingInfoHeatmapConfigNotifier.new);

/// 管理 swing_info_heatmap 設定的 Notifier，加入 debounce 機制。
class SwingInfoHeatmapConfigNotifier extends Notifier<SwingInfoHeatmapConfig> {
  Timer? _debounceTimer;

  @override
  SwingInfoHeatmapConfig build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const SwingInfoHeatmapConfig();
  }

  void _updateWithDebounce(SwingInfoHeatmapConfig Function() updater) {
    final next = updater();
    if (state == next) return;

    // UI 設定立即更新
    state = next;

    // 延遲更新已確認設定（供 API 使用）
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kConfigDebounceDuration, () {
      ref.read(_committedSwingInfoHeatmapConfigProvider.notifier).update(state);
    });
  }

  void updateProjection(String value) {
    if (state.projection == value) return;
    _updateWithDebounce(() => state.copyWith(projection: value));
  }

  void updateSmoothWindowS(double value) {
    final clamped = value.clamp(0.5, 30.0);
    if (_roughlyEqual(state.smoothWindowS, clamped)) return;
    _updateWithDebounce(() => state.copyWith(smoothWindowS: clamped));
  }

  void updateMinVAbs(double value) {
    final clamped = value.clamp(1.0, 80.0);
    if (_roughlyEqual(state.minVAbs, clamped)) return;
    _updateWithDebounce(() => state.copyWith(minVAbs: clamped));
  }

  void updateFlatFrac(double value) {
    final clamped = value.clamp(0.1, 1.2);
    if (_roughlyEqual(state.flatFrac, clamped)) return;
    _updateWithDebounce(() => state.copyWith(flatFrac: clamped));
  }

  void updateMaxMinutes(int? value) {
    if (state.maxMinutes == value) return;
    _updateWithDebounce(() => state.copyWith(maxMinutes: value));
  }

  void updateVminPct(double? value) {
    if (_roughlyEqualNullable(state.vminPct, value)) return;
    // 視覺化用色階設定：只影響前端渲染，不應觸發 API / FutureProvider 重新載入。
    state = state.copyWith(vminPct: value);
  }

  void updateVmaxPct(double? value) {
    if (_roughlyEqualNullable(state.vmaxPct, value)) return;
    // 視覺化用色階設定：只影響前端渲染，不應觸發 API / FutureProvider 重新載入。
    state = state.copyWith(vmaxPct: value);
  }

  void useAutoColorRange() {
    if (state.vminPct == null && state.vmaxPct == null) return;
    // Auto 色階只需回到「依資料自動計算」，不應觸發 provider loading 閃爍。
    state = state.copyWith(clearColorRange: true);
  }

  void reset() {
    _debounceTimer?.cancel();
    state = const SwingInfoHeatmapConfig();
    // reset 時立即更新已確認設定
    ref
        .read(_committedSwingInfoHeatmapConfigProvider.notifier)
        .update(state);
  }
}

/// 提供 swing_info_heatmap 設定（UI 用）。
final swingInfoHeatmapConfigProvider =
    NotifierProvider<SwingInfoHeatmapConfigNotifier, SwingInfoHeatmapConfig>(
      SwingInfoHeatmapConfigNotifier.new,
    );

/// 取得 swing_info_heatmap 資料，使用已確認設定以便 debounce。
final swingInfoHeatmapProvider = FutureProvider<SwingInfoHeatmapResponse>((ref) async {
  final sessionName = ref.watch(activeSessionProvider).trim();
  if (sessionName.isEmpty) {
    ref.read(requestFailureStoreProvider.notifier).clearFailure(
          _kSwingInfoHeatmapRequestId,
        );
    return SwingInfoHeatmapResponse.empty;
  }

  final config = ref.watch(_committedSwingInfoHeatmapConfigProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  final fingerprint = Object.hash(sessionName, config.toJson().toString());

  return fetchWithFailureGate(
    ref,
    requestId: _kSwingInfoHeatmapRequestId,
    fingerprint: fingerprint,
    fetch: () =>
        repository.fetchSwingInfoHeatmap(sessionName: sessionName, config: config),
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
