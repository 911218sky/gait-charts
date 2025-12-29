import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/debounce_config.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import '../sessions/active_session_provider.dart';

const String _kSpatialSpectrumRequestId = 'spatial_spectrum';

/// 已確認的設定（用於 API 呼叫，debounce 後才更新）
class _CommittedConfigNotifier extends Notifier<SpatialSpectrumConfig> {
  @override
  SpatialSpectrumConfig build() => const SpatialSpectrumConfig();

  void update(SpatialSpectrumConfig config) => state = config;
}

final _committedSpatialSpectrumConfigProvider =
    NotifierProvider<_CommittedConfigNotifier, SpatialSpectrumConfig>(
      _CommittedConfigNotifier.new,
    );

/// 空間頻譜設定的 Riverpod Notifier，加入 debounce 機制。
class SpatialSpectrumConfigNotifier extends Notifier<SpatialSpectrumConfig> {
  Timer? _debounceTimer;

  @override
  SpatialSpectrumConfig build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const SpatialSpectrumConfig();
  }

  void _updateWithDebounce(SpatialSpectrumConfig Function() updater) {
    final newState = updater();
    if (state == newState) {
      return;
    }
    // UI 設定立即更新
    state = newState;

    // 延遲更新已確認設定（供 API 使用）
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kConfigDebounceDuration, () {
      ref.read(_committedSpatialSpectrumConfigProvider.notifier).update(state);
    });
  }

  void updateKSmooth(int value) {
    if (state.kSmooth == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(kSmooth: value));
  }

  void updateTopK(int? value) {
    // 0 表示不限制（null）
    final normalized = value == null || value <= 0 ? null : value;
    if (state.topK == normalized) {
      return;
    }
    _updateWithDebounce(
      () => normalized == null
          ? state.copyWith(clearTopK: true)
          : state.copyWith(topK: normalized),
    );
  }

  void updateMinPeakDistance(double value) {
    if (_roughlyEqual(state.minPeakDistanceRatio, value)) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(minPeakDistanceRatio: value));
  }

  void updateMinDb(double value) {
    if (_roughlyEqual(state.minDb, value)) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(minDb: value));
  }

  void updateMinFreq(double value) {
    if (_roughlyEqual(state.minFreq, value)) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(minFreq: value));
  }

  void togglePair(String pair) {
    final normalized = pair.trim().toLowerCase();
    _updateWithDebounce(() => state.copyWith(pairs: [normalized]));
  }

  void selectPair(String pair) => togglePair(pair);

  void reset() {
    _debounceTimer?.cancel();
    state = const SpatialSpectrumConfig();
    // reset 時立即更新已確認設定
    ref.read(_committedSpatialSpectrumConfigProvider.notifier).update(state);
  }
}

/// 空間頻譜設定 Provider。
final spatialSpectrumConfigProvider =
    NotifierProvider<SpatialSpectrumConfigNotifier, SpatialSpectrumConfig>(
      SpatialSpectrumConfigNotifier.new,
    );

/// 空間頻譜資料來源，使用已確認設定實現真正的 debounce。
final spatialSpectrumProvider = FutureProvider<SpatialSpectrumResponse>((
  ref,
) async {
  final sessionName = ref.watch(activeSessionProvider).trim();
  if (sessionName.isEmpty) {
    ref.read(requestFailureStoreProvider.notifier).clearFailure(
          _kSpatialSpectrumRequestId,
        );
    return SpatialSpectrumResponse.empty;
  }
  // 監聽已確認設定，只有 debounce 後才會觸發 API
  final config = ref.watch(_committedSpatialSpectrumConfigProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  final fingerprint = Object.hash(sessionName, config.toJson().toString());
  return fetchWithFailureGate(
    ref,
    requestId: _kSpatialSpectrumRequestId,
    fingerprint: fingerprint,
    fetch: () => repository.fetchSpatialSpectrum(
      sessionName: sessionName,
      config: config,
    ),
  );
});

const List<String> spatialSpectrumPairOptions = ['xz', 'yz'];

bool _roughlyEqual(double a, double b, {double tolerance = 1e-3}) =>
    (a - b).abs() < tolerance;
