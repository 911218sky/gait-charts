import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/debounce_config.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import '../sessions/active_session_provider.dart';

const String _kYHeightDiffRequestId = 'y_height_diff';

/// 已確認的設定（用於 API 呼叫，debounce 後才更新）
class _CommittedConfigNotifier extends Notifier<YHeightDiffConfig> {
  @override
  YHeightDiffConfig build() => const YHeightDiffConfig();

  void update(YHeightDiffConfig config) => state = config;
}

final _committedYHeightDiffConfigProvider =
    NotifierProvider<_CommittedConfigNotifier, YHeightDiffConfig>(
      _CommittedConfigNotifier.new,
    );

/// 管理 y_height_diff 設定的 Notifier，加入 debounce 機制。
/// UI 設定立即更新，API 設定延遲更新。
class YHeightDiffConfigNotifier extends Notifier<YHeightDiffConfig> {
  Timer? _debounceTimer;

  @override
  YHeightDiffConfig build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const YHeightDiffConfig();
  }

  void _updateWithDebounce(YHeightDiffConfig Function() updater) {
    final newState = updater();
    if (state == newState) {
      return;
    }
    // UI 設定立即更新
    state = newState;

    // 延遲更新已確認設定（供 API 使用）
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kConfigDebounceDuration, () {
      ref.read(_committedYHeightDiffConfigProvider.notifier).update(state);
    });
  }

  void updateSmoothWindow(int value) {
    if (state.smoothWindow == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(smoothWindow: value));
  }

  void updateLeftJoint(int value) {
    if (state.leftJoint == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(leftJoint: value));
  }

  void updateRightJoint(int value) {
    if (state.rightJoint == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(rightJoint: value));
  }

  void updateShiftToZero(bool value) {
    if (state.shiftToZero == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(shiftToZero: value));
  }

  /// 套用預設組合，一次更新左右關節與可選平滑窗。
  void applyPreset({int? leftJoint, int? rightJoint, int? smoothWindow}) {
    _updateWithDebounce(
      () => state.copyWith(
        leftJoint: leftJoint,
        rightJoint: rightJoint,
        smoothWindow: smoothWindow,
        shiftToZero: state.shiftToZero,
      ),
    );
  }

  void reset() {
    _debounceTimer?.cancel();
    state = const YHeightDiffConfig();
    // reset 時立即更新已確認設定
    ref.read(_committedYHeightDiffConfigProvider.notifier).update(state);
  }
}

/// 提供 y_height_diff 設定（UI 用）。
final yHeightDiffConfigProvider =
    NotifierProvider<YHeightDiffConfigNotifier, YHeightDiffConfig>(
      YHeightDiffConfigNotifier.new,
    );

/// 取得左右關節高度差資料。
/// 使用已確認設定，實現真正的 debounce 效果。
final yHeightDiffProvider = FutureProvider<YHeightDiffResponse>((ref) async {
  final sessionName = ref.watch(activeSessionProvider).trim();
  if (sessionName.isEmpty) {
    ref.read(requestFailureStoreProvider.notifier).clearFailure(
          _kYHeightDiffRequestId,
        );
    return YHeightDiffResponse.empty;
  }
  
  // 監聽已確認設定，只有 debounce 後才會觸發 API
  final config = ref.watch(_committedYHeightDiffConfigProvider);
  final repository = ref.watch(dashboardRepositoryProvider);
  final fingerprint = Object.hash(
    sessionName,
    config.smoothWindow,
    config.leftJoint,
    config.rightJoint,
    config.shiftToZero,
  );

  return fetchWithFailureGate(
    ref,
    requestId: _kYHeightDiffRequestId,
    fingerprint: fingerprint,
    fetch: () => repository.fetchYHeightDiff(sessionName: sessionName, config: config),
  );
});
