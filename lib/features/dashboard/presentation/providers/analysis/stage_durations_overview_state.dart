import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import '../sessions/active_session_provider.dart';
import 'stage_durations_state.dart';

/// Session 全局趨勢（分段柱狀圖）過濾/高亮設定。
@immutable
class StageDurationsOverviewFilter {
  const StageDurationsOverviewFilter({
    this.selectedStages = const {},
    this.highlightRangePct = const RangeValues(0, 100),
    this.dimNonMatching = true,
    this.onlySelectedLap = false,
  });

  final Set<String> selectedStages;
  final RangeValues highlightRangePct; // 0..100
  final bool dimNonMatching;
  final bool onlySelectedLap;

  StageDurationsOverviewFilter copyWith({
    Set<String>? selectedStages,
    RangeValues? highlightRangePct,
    bool? dimNonMatching,
    bool? onlySelectedLap,
  }) {
    return StageDurationsOverviewFilter(
      selectedStages: selectedStages ?? this.selectedStages,
      highlightRangePct: highlightRangePct ?? this.highlightRangePct,
      dimNonMatching: dimNonMatching ?? this.dimNonMatching,
      onlySelectedLap: onlySelectedLap ?? this.onlySelectedLap,
    );
  }
}

class StageDurationsOverviewFilterNotifier
    extends Notifier<StageDurationsOverviewFilter> {
  @override
  StageDurationsOverviewFilter build() => const StageDurationsOverviewFilter();

  void setSelectedStages(Set<String> labels) =>
      state = state.copyWith(selectedStages: labels);

  void toggleStage(String label) {
    final next = {...state.selectedStages};
    if (!next.add(label)) {
      next.remove(label);
    }
    state = state.copyWith(selectedStages: next);
  }

  void clearStages() => state = state.copyWith(selectedStages: const {});

  void setHighlightRange(RangeValues range) {
    final start = range.start.clamp(0.0, 100.0);
    final end = range.end.clamp(0.0, 100.0);
    state = state.copyWith(highlightRangePct: RangeValues(start, end));
  }

  void setDimNonMatching(bool value) =>
      state = state.copyWith(dimNonMatching: value);

  void setOnlySelectedLap(bool value) =>
      state = state.copyWith(onlySelectedLap: value);

  void reset() => state = const StageDurationsOverviewFilter();
}

final stageDurationsOverviewFilterProvider = NotifierProvider<
    StageDurationsOverviewFilterNotifier,
    StageDurationsOverviewFilter>(
  StageDurationsOverviewFilterNotifier.new,
);

@immutable
class StageDurationsOverviewViewModel {
  const StageDurationsOverviewViewModel({
    required this.stageLabels,
    required this.laps,
    required this.selectedStages,
    required this.highlightRangePct,
    required this.dimNonMatching,
    required this.onlySelectedLap,
    required this.speedPctByLapIndex,
    required this.isHighlightedByLapIndex,
  });

  final List<String> stageLabels;
  final List<LapSummary> laps;
  final Set<String> selectedStages;
  final RangeValues highlightRangePct;
  final bool dimNonMatching;
  final bool onlySelectedLap;

  /// 以「單圈總耗時」換算的速度百分位（0..100，越大代表越快）。
  ///
  /// - 100：最快圈
  /// - 0：最慢圈
  /// - 若只有 1 圈，固定為 100
  final Map<int, double> speedPctByLapIndex;

  /// 是否落在高亮區間內。
  final Map<int, bool> isHighlightedByLapIndex;

  StageDurationsOverviewViewModel copyWith({
    List<String>? stageLabels,
    List<LapSummary>? laps,
    Set<String>? selectedStages,
    RangeValues? highlightRangePct,
    bool? dimNonMatching,
    bool? onlySelectedLap,
    Map<int, double>? speedPctByLapIndex,
    Map<int, bool>? isHighlightedByLapIndex,
  }) {
    return StageDurationsOverviewViewModel(
      stageLabels: stageLabels ?? this.stageLabels,
      laps: laps ?? this.laps,
      selectedStages: selectedStages ?? this.selectedStages,
      highlightRangePct: highlightRangePct ?? this.highlightRangePct,
      dimNonMatching: dimNonMatching ?? this.dimNonMatching,
      onlySelectedLap: onlySelectedLap ?? this.onlySelectedLap,
      speedPctByLapIndex: speedPctByLapIndex ?? this.speedPctByLapIndex,
      isHighlightedByLapIndex:
          isHighlightedByLapIndex ?? this.isHighlightedByLapIndex,
    );
  }

  static const empty = StageDurationsOverviewViewModel(
    stageLabels: [],
    laps: [],
    selectedStages: {},
    highlightRangePct: RangeValues(0, 100),
    dimNonMatching: true,
    onlySelectedLap: false,
    speedPctByLapIndex: {},
    isHighlightedByLapIndex: {},
  );
}

/// 組裝 Session 全局趨勢圖需要的資料（避免在 build() 做聚合運算）。
final stageDurationsOverviewViewModelProvider =
    Provider<StageDurationsOverviewViewModel>((ref) {
  final filter = ref.watch(stageDurationsOverviewFilterProvider);
  final selectedLap = ref.watch(selectedLapIndexProvider);

  final responseAsync = ref.watch(stageDurationsProvider);
  return responseAsync.maybeWhen(
    data: (response) {
      if (response.laps.isEmpty) {
        return StageDurationsOverviewViewModel.empty.copyWith(
          selectedStages: filter.selectedStages,
          highlightRangePct: filter.highlightRangePct,
          dimNonMatching: filter.dimNonMatching,
          onlySelectedLap: filter.onlySelectedLap,
        );
      }

      final laps = filter.onlySelectedLap && selectedLap != null
          ? response.laps.where((l) => l.lapIndex == selectedLap).toList()
          : response.laps;

      // Stage label 順序：以第一圈為主，後續補上沒出現過的 label。
      final labelOrder = <String>[];
      final seen = <String>{};
      void addLabel(String label) {
        if (label.isEmpty) return;
        if (seen.add(label)) {
          labelOrder.add(label);
        }
      }

      for (final s in response.laps.first.stages) {
        addLabel(s.label);
      }
      for (final lap in response.laps.skip(1)) {
        for (final s in lap.stages) {
          addLabel(s.label);
        }
      }

      // 以「單圈總耗時」計算速度百分位（越快越大）。
      final speedPct = _computeSpeedPercentilesByLapIndex(laps);

      final start = filter.highlightRangePct.start;
      final end = filter.highlightRangePct.end;
      final highlights = <int, bool>{
        for (final entry in speedPct.entries)
          entry.key: entry.value >= start && entry.value <= end,
      };

      return StageDurationsOverviewViewModel(
        stageLabels: labelOrder,
        laps: laps,
        selectedStages: filter.selectedStages,
        highlightRangePct: filter.highlightRangePct,
        dimNonMatching: filter.dimNonMatching,
        onlySelectedLap: filter.onlySelectedLap,
        speedPctByLapIndex: speedPct,
        isHighlightedByLapIndex: highlights,
      );
    },
    orElse: () => StageDurationsOverviewViewModel.empty.copyWith(
      selectedStages: filter.selectedStages,
      highlightRangePct: filter.highlightRangePct,
      dimNonMatching: filter.dimNonMatching,
      onlySelectedLap: filter.onlySelectedLap,
    ),
  );
});

Map<int, double> _computeSpeedPercentilesByLapIndex(List<LapSummary> laps) {
  if (laps.isEmpty) return const {};

  double lapTotalSeconds(LapSummary lap) {
    final total = lap.totalDurationSeconds;
    if (total > 0) return total;
    return lap.stages.fold<double>(0, (sum, s) => sum + s.durationSeconds);
  }

  final entries = [
    for (final lap in laps) (lapIndex: lap.lapIndex, seconds: lapTotalSeconds(lap)),
  ];

  // 由快到慢：seconds 小代表快
  entries.sort((a, b) => a.seconds.compareTo(b.seconds));
  final n = entries.length;
  if (n == 1) {
    return {entries.first.lapIndex: 100.0};
  }

  const eps = 1e-9;
  final result = <int, double>{};
  var i = 0;
  while (i < n) {
    final s = entries[i].seconds;
    var j = i + 1;
    while (j < n && (entries[j].seconds - s).abs() < eps) {
      j++;
    }

    // ties：取平均名次
    final avgIndex = (i + (j - 1)) / 2.0;
    final pct = (1.0 - (avgIndex / (n - 1))) * 100.0;
    for (var k = i; k < j; k++) {
      result[entries[k].lapIndex] = pct;
    }
    i = j;
  }
  return result;
}


