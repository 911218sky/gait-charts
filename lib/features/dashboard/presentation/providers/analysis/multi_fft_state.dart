import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/debounce_config.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import '../sessions/active_session_provider.dart';

const String _kMultiFftRequestId = 'multi_fft_from_series';

/// 已確認的設定（用於 API 呼叫，debounce 後才更新）
class _CommittedConfigNotifier extends Notifier<MultiFftFromSeriesConfig> {
  @override
  MultiFftFromSeriesConfig build() => const MultiFftFromSeriesConfig();

  void update(MultiFftFromSeriesConfig config) => state = config;
}

final _committedMultiFftConfigProvider =
    NotifierProvider<_CommittedConfigNotifier, MultiFftFromSeriesConfig>(
      _CommittedConfigNotifier.new,
    );

/// 多頻譜設定狀態，加入 debounce 機制。
class MultiFftConfigNotifier extends Notifier<MultiFftFromSeriesConfig> {
  Timer? _debounceTimer;

  @override
  MultiFftFromSeriesConfig build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const MultiFftFromSeriesConfig();
  }

  void _updateWithDebounce(MultiFftFromSeriesConfig Function() updater) {
    final newState = updater();
    if (state == newState) {
      return;
    }
    // UI 設定立即更新
    state = newState;

    // 延遲更新已確認設定（供 API 使用）
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kConfigDebounceDuration, () {
      ref.read(_committedMultiFftConfigProvider.notifier).update(state);
    });
  }

  void updateComponent(String component) {
    final normalized = component.toLowerCase();
    if (state.component == normalized) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(component: normalized));
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

  void updateFftParams(FftPeriodogramParams params) {
    if (state.fftParams == params) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(fftParams: params));
  }

  void togglePreset(String id) {
    final current = List<MultiFftJointSelection>.from(state.joints);
    final preset = _findPreset(id);
    if (preset == null) {
      return;
    }
    if (current.length == 1 && current.first.id == preset.id) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(joints: [preset]));
  }

  void setPresets(List<String> ids) {
    final resolved = ids
        .map(_findPreset)
        .whereType<MultiFftJointSelection>()
        .toList(growable: false);
    if (resolved.isEmpty) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(joints: resolved));
  }

  void reset() {
    _debounceTimer?.cancel();
    state = const MultiFftFromSeriesConfig();
    // reset 時立即更新已確認設定
    ref.read(_committedMultiFftConfigProvider.notifier).update(state);
  }

  MultiFftJointSelection? _findPreset(String id) {
    for (final preset in kMultiFftJointPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }
}

/// 多 FFT 設定 Provider。
final multiFftConfigProvider =
    NotifierProvider<MultiFftConfigNotifier, MultiFftFromSeriesConfig>(
      MultiFftConfigNotifier.new,
    );

/// 多 FFT 頻譜資料 Provider，使用已確認設定實現真正的 debounce。
final multiFftSeriesProvider = FutureProvider<MultiFftSeriesResponse>((
  ref,
) async {
  final sessionName = ref.watch(activeSessionProvider).trim();
  if (sessionName.isEmpty) {
    ref.read(requestFailureStoreProvider.notifier).clearFailure(
          _kMultiFftRequestId,
        );
    return MultiFftSeriesResponse.empty;
  }
  // 監聽已確認設定，只有 debounce 後才會觸發 API
  final config = ref.watch(_committedMultiFftConfigProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  final fingerprint = Object.hash(sessionName, config.toJson().toString());
  final response = await fetchWithFailureGate(
    ref,
    requestId: _kMultiFftRequestId,
    fingerprint: fingerprint,
    fetch: () => repository.fetchMultiFftFromSeries(
      sessionName: sessionName,
      config: config,
    ),
  );
  if (response.isEmpty) {
    return response;
  }
  return MultiFftSeriesResponse(
    component: response.component,
    series: response.series,
  );
});

bool _roughlyEqual(double a, double b, {double tolerance = 1e-3}) =>
    (a - b).abs() < tolerance;
