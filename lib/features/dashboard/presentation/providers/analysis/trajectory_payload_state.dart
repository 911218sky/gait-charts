import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/core/config/debounce_config.dart';
import 'package:gait_charts/core/providers/request_failure_store.dart';
import 'package:gait_charts/features/dashboard/data/dashboard_repository.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import '../sessions/active_session_provider.dart';

const String _kTrajectoryPayloadRequestId = 'trajectory_payload';

/// 已確認的設定（用於 API 呼叫，debounce 後才更新）。
class _CommittedTrajectoryPayloadConfigNotifier
    extends Notifier<TrajectoryPayloadConfig> {
  @override
  TrajectoryPayloadConfig build() => const TrajectoryPayloadConfig();

  void update(TrajectoryPayloadConfig config) => state = config;
}

final _committedTrajectoryPayloadConfigProvider = NotifierProvider<
  _CommittedTrajectoryPayloadConfigNotifier,
  TrajectoryPayloadConfig
>(
  _CommittedTrajectoryPayloadConfigNotifier.new,
);

/// trajectory_payload 設定狀態（UI 即時更新 + debounce 後更新 committed 設定）。
class TrajectoryPayloadConfigNotifier extends Notifier<TrajectoryPayloadConfig> {
  Timer? _debounceTimer;

  @override
  TrajectoryPayloadConfig build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const TrajectoryPayloadConfig();
  }

  void _updateWithDebounce(TrajectoryPayloadConfig Function() updater) {
    final next = updater();
    if (state == next) {
      return;
    }
    state = next;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kConfigDebounceDuration, () {
      ref.read(_committedTrajectoryPayloadConfigProvider.notifier).update(state);
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

  void updateLeftJoint(Object value) {
    if (state.leftJoint == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(leftJoint: value));
  }

  void updateRightJoint(Object value) {
    if (state.rightJoint == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(rightJoint: value));
  }

  void applyJointPreset({required Object leftJoint, required Object rightJoint}) {
    if (state.leftJoint == leftJoint && state.rightJoint == rightJoint) {
      return;
    }
    _updateWithDebounce(
      () => state.copyWith(leftJoint: leftJoint, rightJoint: rightJoint),
    );
  }

  void updateFpsOut(int value) {
    final clamped = value.clamp(1, 120);
    if (state.fpsOut == clamped) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(fpsOut: clamped));
  }

  void updateSpeed(double value) {
    final clamped = value.clamp(0.1, 5.0);
    if (_roughlyEqual(state.speed, clamped)) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(speed: clamped));
  }

  void updateFrameJump(int value) {
    final clamped = value.clamp(1, 20);
    if (state.frameJump == clamped) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(frameJump: clamped));
  }

  void updateRotate180(bool value) {
    if (state.rotate180 == value) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(rotate180: value));
  }

  void updatePadScale(double value) {
    final clamped = value.clamp(0.0, 0.5);
    if (_roughlyEqual(state.padScale, clamped)) {
      return;
    }
    _updateWithDebounce(() => state.copyWith(padScale: clamped));
  }

  void reset() {
    _debounceTimer?.cancel();
    state = const TrajectoryPayloadConfig();
    ref.read(_committedTrajectoryPayloadConfigProvider.notifier).update(state);
  }
}

final trajectoryPayloadConfigProvider = NotifierProvider<
  TrajectoryPayloadConfigNotifier,
  TrajectoryPayloadConfig
>(
  TrajectoryPayloadConfigNotifier.new,
);

/// 取得並 decode trajectory payload（解壓/反量化在 provider 完成，UI 只負責畫）。
final trajectoryPayloadProvider =
    FutureProvider.autoDispose<TrajectoryDecodedPayload>((ref) async {
      final sessionName = ref.watch(activeSessionProvider).trim();
      if (sessionName.isEmpty) {
        ref.read(requestFailureStoreProvider.notifier).clearFailure(
              _kTrajectoryPayloadRequestId,
            );
        return TrajectoryDecodedPayload.empty;
      }

      final config = ref.watch(_committedTrajectoryPayloadConfigProvider);
      final repository = ref.watch(dashboardRepositoryProvider);
      final fingerprint = Object.hash(sessionName, config.toJson().toString());

      final response = await fetchWithFailureGate(
        ref,
        requestId: _kTrajectoryPayloadRequestId,
        fingerprint: fingerprint,
        fetch: () => repository.fetchTrajectoryPayload(
          sessionName: sessionName,
          config: config,
        ),
      );
      return decodeTrajectoryPayload(response);
    });

/// 判斷兩個 double 是否在容許範圍內相等。
bool _roughlyEqual(double a, double b, {double tolerance = 1e-3}) =>
    (a - b).abs() < tolerance;