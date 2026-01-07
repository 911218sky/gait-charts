import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/core/storage/trajectory_overlay_storage.dart';

/// 控制軌跡播放器的場景覆蓋層顯示（僅影響前端 UI）。
class TrajectoryOverlayUiState {
  const TrajectoryOverlayUiState({
    this.showChairArea = false,
    this.showConeArea = false,
    this.showFullTrail = true, // 默認顯示全部軌跡
  });

  final bool showChairArea;
  final bool showConeArea;
  final bool showFullTrail;

  TrajectoryOverlayUiState copyWith({
    bool? showChairArea,
    bool? showConeArea,
    bool? showFullTrail,
  }) {
    return TrajectoryOverlayUiState(
      showChairArea: showChairArea ?? this.showChairArea,
      showConeArea: showConeArea ?? this.showConeArea,
      showFullTrail: showFullTrail ?? this.showFullTrail,
    );
  }
}

class TrajectoryOverlayUiNotifier extends Notifier<TrajectoryOverlayUiState> {
  TrajectoryOverlayStorage get _storage =>
      ref.read(trajectoryOverlayStorageProvider);

  @override
  TrajectoryOverlayUiState build() {
    // 先用預設值，避免 UI 等待 IO；再從本機偏好設定背景還原。
    unawaited(_restore());
    return const TrajectoryOverlayUiState();
  }

  Future<void> _restore() async {
    try {
      final saved = await _storage.readShowFullTrail();
      if (!ref.mounted || saved == null) {
        return;
      }
      state = state.copyWith(showFullTrail: saved);
    } catch (_) {
      // 讀取失敗就維持預設，不影響啟動。
    }
  }

  void toggleChairArea(bool value) =>
      state = state.copyWith(showChairArea: value);

  void toggleConeArea(bool value) =>
      state = state.copyWith(showConeArea: value);

  void toggleFullTrail(bool value) {
    state = state.copyWith(showFullTrail: value);
    unawaited(_storage.writeShowFullTrail(value));
  }
}

/// Trajectory overlay 偏好設定的本機儲存層 Provider。
final trajectoryOverlayStorageProvider = Provider<TrajectoryOverlayStorage>((ref) {
  return TrajectoryOverlayStorage();
});

final trajectoryOverlayUiProvider =
    NotifierProvider<TrajectoryOverlayUiNotifier, TrajectoryOverlayUiState>(
      TrajectoryOverlayUiNotifier.new,
    );
