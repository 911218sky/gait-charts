import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/stage_duration/stage_duration_palette.dart';

/// Session 全局趨勢（按圈展示分期耗時，支援高亮/過濾）。
class SessionOverviewChart extends ConsumerStatefulWidget {
  const SessionOverviewChart({
    required this.laps,
    required this.onLapFocusRequested,
    super.key,
  });

  final List<LapSummary> laps;
  final VoidCallback onLapFocusRequested;

  @override
  ConsumerState<SessionOverviewChart> createState() =>
      _SessionOverviewChartState();
}

class _SessionOverviewChartState extends ConsumerState<SessionOverviewChart> {
  late final ValueNotifier<_TooltipState?> _tooltipNotifier;
  late final ScrollController _scrollController;

  Color _dimStageColor({
    required Color base,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final target = isDark
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerHigh;
    final mixed = Color.lerp(base, target, isDark ? 0.72 : 0.62) ?? base;
    return mixed.withValues(alpha: isDark ? 0.62 : 0.52);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tooltipNotifier = ValueNotifier<_TooltipState?>(null);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tooltipNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    final vm = ref.watch(stageDurationsOverviewViewModelProvider);
    final filter = ref.watch(stageDurationsOverviewFilterProvider);
    final filterNotifier = ref.read(
      stageDurationsOverviewFilterProvider.notifier,
    );
    final selectedLap = ref.watch(selectedLapIndexProvider);

    final laps = vm.laps;
    if (laps.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayedStages = filter.selectedStages.isEmpty
        ? vm.stageLabels
        : vm.stageLabels
              .where(filter.selectedStages.contains)
              .toList(growable: false);

    final chartMaxY = _maxY(laps, displayedStages) * 1.15;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 標題與重置按鈕區域
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '各活動階段耗時變化',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '每圈以「分段堆疊」呈現各階段耗時；可用速度百分位區間高亮（越大越快），點選任一圈快速跳到下方細節。',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    filterNotifier.reset();
                    _tooltipNotifier.value = null;
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: '重置設定',
                  style: IconButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),

          // 控制區塊
          Container(
            color: colors.surfaceContainerLow.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 階段過濾器
                if (vm.stageLabels.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 12),
                        child: Text(
                          '顯示階段',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              selected: filter.selectedStages.isEmpty,
                              showCheckmark: false,
                              label: const Text('全部'),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              side: filter.selectedStages.isEmpty
                                  ? BorderSide.none
                                  : BorderSide(color: colors.outlineVariant),
                              backgroundColor: Colors.transparent,
                              selectedColor: colors.primary.withValues(
                                alpha: isDark ? 0.2 : 0.1,
                              ),
                              labelStyle: TextStyle(
                                color: filter.selectedStages.isEmpty
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                                fontWeight: filter.selectedStages.isEmpty
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              onSelected: (v) {
                                if (v) filterNotifier.clearStages();
                              },
                            ),
                            for (var i = 0; i < vm.stageLabels.length; i++)
                              _StageFilterChip(
                                label: vm.stageLabels[i],
                                color:
                                    stageDurationPalette[i %
                                        stageDurationPalette.length],
                                isSelected:
                                    filter.selectedStages.isEmpty ||
                                    filter.selectedStages.contains(
                                      vm.stageLabels[i],
                                    ),
                                onSelected: () {
                                  if (filter.selectedStages.isEmpty) {
                                    filterNotifier.setSelectedStages({
                                      vm.stageLabels[i],
                                    });
                                  } else {
                                    filterNotifier.toggleStage(
                                      vm.stageLabels[i],
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // 進階篩選與高亮設定
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 根據寬度決定是否分行
                    final isNarrow = constraints.maxWidth < 600;
                    final highlightCount = vm.isHighlightedByLapIndex.values
                        .where((v) => v)
                        .length;
                    return Flex(
                      direction: isNarrow ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: isNarrow
                          ? CrossAxisAlignment.stretch
                          : CrossAxisAlignment.center,
                      children: [
                        // 左側開關
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _SwitchOption(
                              label: '只看目前圈',
                              value: filter.onlySelectedLap,
                              onChanged: selectedLap == null
                                  ? null
                                  : filterNotifier.setOnlySelectedLap,
                              enabled: selectedLap != null,
                            ),
                            _SwitchOption(
                              label: '未命中變暗',
                              value: filter.dimNonMatching,
                              onChanged: filterNotifier.setDimNonMatching,
                            ),
                          ],
                        ),
                        if (!isNarrow) const Spacer(),
                        if (isNarrow) const SizedBox(height: 16),

                        // 右側滑桿
                        Container(
                          constraints: const BoxConstraints(maxWidth: 360),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colors.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '單圈速度百分位篩選（越大越快）',
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: colors.primary.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '${filter.highlightRangePct.start.toStringAsFixed(0)}%–${filter.highlightRangePct.end.toStringAsFixed(0)}%',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w700,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '慢 0%',
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                    ),
                                  ),
                                  Text(
                                    '高亮 $highlightCount / ${laps.length} 圈',
                                    style: context.textTheme.labelSmall
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '100% 快',
                                        style: context.textTheme.labelSmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 24,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    activeTrackColor: colors.primary.withValues(
                                      alpha: 0.65,
                                    ),
                                    inactiveTrackColor: colors.outlineVariant
                                        .withValues(alpha: 0.40),
                                    rangeThumbShape:
                                        const RoundRangeSliderThumbShape(
                                          enabledThumbRadius: 8,
                                        ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                    valueIndicatorShape:
                                        const PaddleSliderValueIndicatorShape(),
                                    valueIndicatorColor: colors.primary,
                                    valueIndicatorTextStyle: TextStyle(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  child: RangeSlider(
                                    values: filter.highlightRangePct,
                                    min: 0,
                                    max: 100,
                                    divisions: 20,
                                    labels: RangeLabels(
                                      '${filter.highlightRangePct.start.toStringAsFixed(0)}%',
                                      '${filter.highlightRangePct.end.toStringAsFixed(0)}%',
                                    ),
                                    onChanged: filterNotifier.setHighlightRange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // 圖表區域
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: SizedBox(
              height: 340,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  // 調整每圈寬度，讓視覺更寬鬆
                  const perLapWidth = 36.0;
                  final contentMinWidth = math.max(
                    constraints.maxWidth,
                    laps.length * perLapWidth + 60,
                  );

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: contentMinWidth,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 24,
                                bottom: 12,
                              ),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  minY: 0,
                                  maxY: chartMaxY,
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    handleBuiltInTouches: false,
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipPadding: EdgeInsets.zero,
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) =>
                                              BarTooltipItem(
                                                '',
                                                const TextStyle(),
                                              ),
                                    ),
                                    touchCallback: (event, response) =>
                                        _handleTouch(event, response, vm),
                                  ),
                                  gridData: FlGridData(
                                    drawHorizontalLine: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: colors.outlineVariant.withValues(
                                        alpha: 0.4,
                                      ),
                                      strokeWidth: 1,
                                      dashArray: [4, 4],
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: colors.outlineVariant,
                                      ),
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) => Text(
                                          '${value.toStringAsFixed(0)}s',
                                          style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 28,
                                        interval: _lapLabelInterval(
                                          laps.length,
                                        ),
                                        getTitlesWidget: (value, meta) {
                                          final v = value.toInt();
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              'L$v',
                                              style: TextStyle(
                                                color: colors.onSurfaceVariant,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: [
                                    for (final lap in laps)
                                      _buildLapGroup(
                                        lap: lap,
                                        vm: vm,
                                        displayedStages: displayedStages,
                                        isSelected: selectedLap == lap.lapIndex,
                                        chartMaxY: chartMaxY,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ValueListenableBuilder<_TooltipState?>(
                        valueListenable: _tooltipNotifier,
                        builder: (context, tooltip, _) {
                          if (tooltip == null) return const SizedBox.shrink();
                          return Positioned(
                            left: (tooltip.position.dx - 110).clamp(
                              0.0,
                              chartSize.width - 220,
                            ),
                            top: (tooltip.position.dy - 140).clamp(
                              0.0,
                              chartSize.height - 160,
                            ),
                            child: IgnorePointer(
                              child: DashboardGlassTooltip(
                                child: _OverviewTooltipContent(
                                  lapIndex: tooltip.lapIndex,
                                  totalSeconds: tooltip.totalSeconds,
                                  ratioPct: tooltip.ratioPct,
                                  stages: tooltip.stages,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _maxY(List<LapSummary> laps, List<String> displayedStages) {
    var maxTotal = 0.0;
    for (final lap in laps) {
      final total = lap.totalDurationSeconds <= 0
          ? lap.stages.fold<double>(0, (sum, s) => sum + s.durationSeconds)
          : lap.totalDurationSeconds;
      if (displayedStages.length == lap.stages.length) {
        maxTotal = math.max(maxTotal, total);
        continue;
      }
      final selected = lap.stages
          .where((s) => displayedStages.contains(s.label))
          .fold<double>(0, (sum, s) => sum + s.durationSeconds);
      maxTotal = math.max(maxTotal, selected);
    }
    return maxTotal <= 0 ? 1.0 : maxTotal;
  }

  double _lapLabelInterval(int count) {
    if (count <= 0) return 1;
    if (count <= 14) return 1;
    if (count <= 28) return 2;
    if (count <= 50) return 4;
    return 6;
  }

  BarChartGroupData _buildLapGroup({
    required LapSummary lap,
    required StageDurationsOverviewViewModel vm,
    required List<String> displayedStages,
    required bool isSelected,
    required double chartMaxY,
  }) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    final total = lap.totalDurationSeconds <= 0
        ? lap.stages.fold<double>(0, (sum, s) => sum + s.durationSeconds)
        : lap.totalDurationSeconds;

    final isHighlighted = vm.isHighlightedByLapIndex[lap.lapIndex] ?? true;
    // 選中圈永遠不變暗，避免互動上「選了但看不清」的割裂感
    final dim = !isSelected && vm.dimNonMatching && !isHighlighted;

    var acc = 0.0;
    final items = <BarChartRodStackItem>[];
    // Reorder displayed stages to match palette order logic if needed,
    // but here we follow the order of `displayedStages`.

    for (var i = 0; i < displayedStages.length; i++) {
      final label = displayedStages[i];
      final value = lap.stages
          .where((s) => s.label == label)
          .fold<double>(0, (sum, s) => sum + s.durationSeconds);
      if (value <= 0) continue;

      // Find original index for consistent coloring
      final originalIndex = vm.stageLabels.indexOf(label);
      final colorIndex = originalIndex >= 0 ? originalIndex : i;
      final base =
          stageDurationPalette[colorIndex % stageDurationPalette.length];

      final color = dim
          ? _dimStageColor(base: base, scheme: colors, isDark: isDark)
          : base;

      // Add slight gap between segments by using a border or margin logic?
      // fl_chart stack items are continuous. We can simulate gap by adding a transparent item,
      // but that complicates height calc.
      // Instead, we just trust the colors.

      items.add(BarChartRodStackItem(acc, acc + value, color));
      acc += value;
    }

    final rod = BarChartRodData(
      toY: acc <= 0 ? total : acc,
      width: 22, // 稍微加寬
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(6),
      ), // 只圓上面
      rodStackItems: items,
      backDrawRodData: BackgroundBarChartRodData(
        show: isSelected,
        color: colors.primary.withValues(alpha: 0.1),
        toY: chartMaxY, // Highlight background full height
      ),
      borderSide: isSelected
          ? BorderSide(color: colors.primary, width: 2)
          : BorderSide.none,
    );

    return BarChartGroupData(
      x: lap.lapIndex,
      barRods: [rod],
      showingTooltipIndicators: const [],
    );
  }

  void _handleTouch(
    FlTouchEvent event,
    BarTouchResponse? response,
    StageDurationsOverviewViewModel vm,
  ) {
    if (!event.isInterestedForInteractions ||
        response == null ||
        response.spot == null) {
      _tooltipNotifier.value = null;
      return;
    }

    final groupIndex = response.spot!.touchedBarGroupIndex;
    if (groupIndex < 0 || groupIndex >= vm.laps.length) {
      return;
    }
    final lap = vm.laps[groupIndex];
    final localPos = event.localPosition ?? Offset.zero;

    final total = lap.totalDurationSeconds <= 0
        ? lap.stages.fold<double>(0, (sum, s) => sum + s.durationSeconds)
        : lap.totalDurationSeconds;
    final speedPct = vm.speedPctByLapIndex[lap.lapIndex] ?? 0.0;

    final displayedStages = vm.selectedStages.isEmpty
        ? vm.stageLabels
        : vm.stageLabels
              .where((label) => vm.selectedStages.contains(label))
              .toList(growable: false);
    final stages = <String, double>{
      for (final label in displayedStages)
        label: lap.stages
            .where((s) => s.label == label)
            .fold<double>(0, (sum, s) => sum + s.durationSeconds),
    }..removeWhere((k, v) => v <= 0);

    _setTooltipIfChanged(
      _TooltipState(
        lapIndex: lap.lapIndex,
        totalSeconds: total,
        ratioPct: speedPct,
        stages: stages,
        position: localPos,
      ),
    );

    if (event is FlTapUpEvent) {
      ref.read(selectedLapIndexProvider.notifier).select(lap.lapIndex);
      widget.onLapFocusRequested();
    }
  }

  void _setTooltipIfChanged(_TooltipState next) {
    final prev = _tooltipNotifier.value;
    if (prev == null) {
      _tooltipNotifier.value = next;
      return;
    }

    // 只要內容沒變、而且位置只做很小的抖動，就不更新，避免頻繁刷新導致視覺閃動。
    final sameLap = prev.lapIndex == next.lapIndex;
    final sameTotal = (prev.totalSeconds - next.totalSeconds).abs() < 0.001;
    final sameRatio = (prev.ratioPct - next.ratioPct).abs() < 0.001;
    final sameStages =
        prev.stages.length == next.stages.length &&
        _sameStageMap(prev.stages, next.stages);
    final smallMove = (prev.position - next.position).distance < 6.0;

    if (sameLap && sameTotal && sameRatio && sameStages && smallMove) {
      return;
    }
    _tooltipNotifier.value = next;
  }

  bool _sameStageMap(Map<String, double> a, Map<String, double> b) {
    for (final e in a.entries) {
      final v = b[e.key];
      if (v == null) return false;
      if ((v - e.value).abs() >= 0.001) return false;
    }
    return true;
  }
}

class _StageFilterChip extends StatelessWidget {
  const _StageFilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.8)
                : colors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchOption extends StatelessWidget {
  const _SwitchOption({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Switch.adaptive(
                value: value,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TooltipState {
  _TooltipState({
    required this.lapIndex,
    required this.totalSeconds,
    required this.ratioPct,
    required this.stages,
    required this.position,
  });

  final int lapIndex;
  final double totalSeconds;
  final double ratioPct;
  final Map<String, double> stages;
  final Offset position;
}

class _OverviewTooltipContent extends StatelessWidget {
  const _OverviewTooltipContent({
    required this.lapIndex,
    required this.totalSeconds,
    required this.ratioPct,
    required this.stages,
  });

  final int lapIndex;
  final double totalSeconds;
  final double ratioPct;
  final Map<String, double> stages;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lap $lapIndex',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '總耗時 ${totalSeconds.toStringAsFixed(2)} s',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '速度百分位 ${ratioPct.clamp(0, 100).toStringAsFixed(0)}%（越大越快）',
            style: TextStyle(
              color: colors.primary.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (stages.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final entry in stages.entries.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${entry.key}: ${entry.value.toStringAsFixed(2)} s',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.72),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 6),
          Text(
            '點選可跳到細節',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
