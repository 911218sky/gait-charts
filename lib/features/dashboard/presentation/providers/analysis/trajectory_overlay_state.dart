import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 控制軌跡播放器的場景覆蓋層顯示（僅影響前端 UI）。
class TrajectoryOverlayUiState {
  const TrajectoryOverlayUiState({
    this.showChairArea = false,
    this.showConeArea = false,
  });

  final bool showChairArea;
  final bool showConeArea;

  TrajectoryOverlayUiState copyWith({
    bool? showChairArea,
    bool? showConeArea,
  }) {
    return TrajectoryOverlayUiState(
      showChairArea: showChairArea ?? this.showChairArea,
      showConeArea: showConeArea ?? this.showConeArea,
    );
  }
}

class TrajectoryOverlayUiNotifier
    extends Notifier<TrajectoryOverlayUiState> {
  @override
  TrajectoryOverlayUiState build() => const TrajectoryOverlayUiState();

  void toggleChairArea(bool value) =>
      state = state.copyWith(showChairArea: value);

  void toggleConeArea(bool value) =>
      state = state.copyWith(showConeArea: value);
}

final trajectoryOverlayUiProvider = NotifierProvider<
    TrajectoryOverlayUiNotifier, TrajectoryOverlayUiState>(
  TrajectoryOverlayUiNotifier.new,
);

