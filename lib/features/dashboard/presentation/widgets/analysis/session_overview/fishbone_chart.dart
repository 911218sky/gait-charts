import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' hide TooltipState;

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/session_overview/chart_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/session_overview/overview_tooltip.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/stage_duration/stage_duration_palette.dart';

// ─────────────────────────────────────────────────────────────
// 方向統計
// ─────────────────────────────────────────────────────────────

/// 方向統計資料（平均秒數、變異係數 CV）。
typedef DirectionStats = ({double avgSeconds, double cv});

/// 計算方向統計（平均秒數、變異係數 CV）。
///
/// [laps] 該方向的圈數列表，[displayedStages] 要計算的階段列表。
/// 回傳包含平均秒數和變異係數的 record。
DirectionStats computeDirectionStats(
  List<LapSummary> laps,
  List<String> displayedStages,
) {
  if (laps.isEmpty) return (avgSeconds: 0, cv: 0);

  final durations = laps.map((lap) {
    return lap.stages
        .where(
            (s) => displayedStages.isEmpty || displayedStages.contains(s.label))
        .fold<double>(0, (sum, s) => sum + s.durationSeconds);
  }).toList();

  final avg = durations.fold<double>(0, (sum, d) => sum + d) / durations.length;
  if (avg <= 0) return (avgSeconds: 0, cv: 0);

  // 計算標準差
  final variance =
      durations.fold<double>(0, (sum, d) => sum + math.pow(d - avg, 2)) /
          durations.length;
  final stdDev = math.sqrt(variance);
  final cv = stdDev / avg;

  return (avgSeconds: avg, cv: cv);
}

// ─────────────────────────────────────────────────────────────
// 魚骨圖元件
// ─────────────────────────────────────────────────────────────

/// 魚骨圖元件：順時鐘往上、逆時鐘往下，從中間軸分開。
///
/// 用於以方向分組顯示圈數資料，順時鐘圈數顯示在上方（正值），
/// 逆時鐘圈數顯示在下方（負值）。
class FishboneChart extends StatefulWidget {
  const FishboneChart({
    required this.vm,
    required this.selectedLap,
    required this.displayedStages,
    required this.onLapSelected,
    this.onVideoSeek,
    super.key,
  });

  /// 階段耗時總覽 ViewModel。
  final StageDurationsOverviewViewModel vm;

  /// 目前選中的圈數索引。
  final int? selectedLap;

  /// 要顯示的階段列表。
  final List<String> displayedStages;

  /// 選中圈數時的回呼。
  final ValueChanged<int> onLapSelected;

  /// 點擊圈數時跳轉到影片對應秒數。
  final void Function(double seconds)? onVideoSeek;

  @override
  State<FishboneChart> createState() => _FishboneChartState();
}

class _FishboneChartState extends State<FishboneChart> {
  late final ScrollController _scrollController;

  // 用 ValueNotifier 避免 setState 重建整個 chart
  final _tooltipState = ValueNotifier<TooltipState?>(null);
  int? _lastTouchedIndex;

  // 延遲隱藏 tooltip，避免閃爍
  bool _isHoveringTooltip = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tooltipState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final vm = widget.vm;

    // 合併所有圈數並按 lapIndex 排序
    final allLaps = [...vm.laps]
      ..sort((a, b) => a.lapIndex.compareTo(b.lapIndex));
    final clockwiseMaxY =
        calculateMaxY(vm.clockwiseLaps, widget.displayedStages) * 1.15;
    final counterclockwiseMaxY =
        calculateMaxY(vm.counterclockwiseLaps, widget.displayedStages) * 1.15;
    final maxY = math.max(clockwiseMaxY, counterclockwiseMaxY);
    if (maxY <= 0) return const SizedBox.shrink();

    // 計算統計資訊
    final cwStats =
        computeDirectionStats(vm.clockwiseLaps, widget.displayedStages);
    final ccwStats =
        computeDirectionStats(vm.counterclockwiseLaps, widget.displayedStages);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 統計資訊標題
          _buildStatsHeader(context, colors, isDark, vm, cwStats, ccwStats),
          const SizedBox(height: 16),
          SizedBox(
            height: 420,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                const perLapWidth = 36.0;
                final contentMinWidth = math.max(
                  constraints.maxWidth,
                  allLaps.length * perLapWidth + 60,
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
                            padding: const EdgeInsets.only(right: 24),
                            child: BarChart(
                              duration: Duration.zero,
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                minY: -maxY,
                                maxY: maxY,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  handleBuiltInTouches: false,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipPadding: EdgeInsets.zero,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) =>
                                            BarTooltipItem(
                                                '', const TextStyle()),
                                  ),
                                  touchCallback: (event, response) =>
                                      _handleTouch(
                                          event, response, vm, allLaps),
                                ),
                                gridData: FlGridData(
                                  drawHorizontalLine: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: value == 0
                                        ? colors.outlineVariant
                                        : colors.outlineVariant
                                            .withValues(alpha: 0.3),
                                    strokeWidth: value == 0 ? 2 : 1,
                                    dashArray: value == 0 ? null : [4, 4],
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: buildFishboneTitlesData(
                                    colors, allLaps, maxY),
                                barGroups: [
                                  for (final lap in allLaps)
                                    buildFishboneLapGroup(
                                      lap: lap,
                                      vm: vm,
                                      displayedStages: widget.displayedStages,
                                      isSelected:
                                          widget.selectedLap == lap.lapIndex,
                                      chartMaxY: maxY,
                                      colors: colors,
                                      isDark: isDark,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Tooltip
                    _buildTooltip(chartSize, allLaps, vm),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 建構統計資訊標題區塊。
  Widget _buildStatsHeader(
    BuildContext context,
    ColorScheme colors,
    bool isDark,
    StageDurationsOverviewViewModel vm,
    DirectionStats cwStats,
    DirectionStats ccwStats,
  ) {
    // 定義顏色
    const cwColor = Color(0xFFFF9800); // 橘色
    const ccwColor = Color(0xFF42A5F5); // 藍色

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // 順時鐘統計
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cwColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.north, size: 18, color: cwColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '順時鐘 ${vm.clockwiseLaps.length} 圈',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: cwColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '平均 ${cwStats.avgSeconds.toStringAsFixed(1)}s ｜ CV ${(cwStats.cv * 100).toStringAsFixed(1)}%',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 分隔線
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
          // 逆時鐘統計
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ccwColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.south, size: 18, color: ccwColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '逆時鐘 ${vm.counterclockwiseLaps.length} 圈',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: ccwColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '平均 ${ccwStats.avgSeconds.toStringAsFixed(1)}s ｜ CV ${(ccwStats.cv * 100).toStringAsFixed(1)}%',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建構 Tooltip。
  Widget _buildTooltip(
    Size chartSize,
    List<LapSummary> allLaps,
    StageDurationsOverviewViewModel vm,
  ) {
    return ValueListenableBuilder<TooltipState?>(
      valueListenable: _tooltipState,
      builder: (context, state, _) {
        if (state == null) return const SizedBox.shrink();
        final lap =
            allLaps.where((l) => l.lapIndex == state.lapIndex).firstOrNull;
        if (lap == null) return const SizedBox.shrink();

        final total = lap.totalDurationSeconds <= 0
            ? lap.stages.fold<double>(0, (sum, s) => sum + s.durationSeconds)
            : lap.totalDurationSeconds;
        final speedPct = vm.speedPctByLapIndex[lap.lapIndex] ?? 0.0;
        final stages = <String, double>{
          for (final label in widget.displayedStages)
            label: lap.stages
                .where((s) => s.label == label)
                .fold<double>(0, (sum, s) => sum + s.durationSeconds),
        }..removeWhere((k, v) => v <= 0);
        final isClockwise =
            lap.isClockwise ? true : (lap.isCounterclockwise ? false : null);

        return Positioned(
          left: (state.position.dx - 130).clamp(0.0, chartSize.width - 260),
          top: (state.position.dy - 180).clamp(0.0, chartSize.height - 200),
          child: MouseRegion(
            onEnter: (_) => _isHoveringTooltip = true,
            onExit: (_) {
              _isHoveringTooltip = false;
              // 延遲檢查，若滑鼠不在 bar 上也不在 tooltip 上才隱藏
              Future.delayed(const Duration(milliseconds: 50), () {
                if (!_isHoveringTooltip && _lastTouchedIndex == null) {
                  _tooltipState.value = null;
                }
              });
            },
            child: DashboardGlassTooltip(
              child: OverviewTooltipContent(
                lapIndex: lap.lapIndex,
                totalSeconds: total,
                ratioPct: speedPct,
                stages: stages,
                videoTimestampSeconds: lap.startTimestampSeconds > 0
                    ? lap.startTimestampSeconds
                    : null,
                isClockwise: isClockwise,
                onVideoSeek:
                    lap.startTimestampSeconds > 0 && widget.onVideoSeek != null
                        ? () => widget.onVideoSeek!(lap.startTimestampSeconds)
                        : null,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 處理觸控事件。
  void _handleTouch(
    FlTouchEvent event,
    BarTouchResponse? response,
    StageDurationsOverviewViewModel vm,
    List<LapSummary> laps,
  ) {
    if (!event.isInterestedForInteractions ||
        response == null ||
        response.spot == null) {
      // 滑鼠離開 bar 時，延遲檢查是否要隱藏 tooltip
      if (_lastTouchedIndex != null) {
        _lastTouchedIndex = null;
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isHoveringTooltip && _lastTouchedIndex == null) {
            _tooltipState.value = null;
          }
        });
      }
      return;
    }

    final groupIndex = response.spot!.touchedBarGroupIndex;
    if (groupIndex < 0 || groupIndex >= laps.length) {
      if (_lastTouchedIndex != null) {
        _lastTouchedIndex = null;
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isHoveringTooltip && _lastTouchedIndex == null) {
            _tooltipState.value = null;
          }
        });
      }
      return;
    }

    final lap = laps[groupIndex];
    final localPos = event.localPosition ?? Offset.zero;

    // 只在 lapIndex 改變時更新（避免閃爍）
    if (_lastTouchedIndex != lap.lapIndex) {
      _lastTouchedIndex = lap.lapIndex;
      _tooltipState.value = TooltipState(
        lapIndex: lap.lapIndex,
        position: localPos,
      );
    }

    if (event is FlTapUpEvent) {
      widget.onLapSelected(lap.lapIndex);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// 魚骨圖建構方法
// ─────────────────────────────────────────────────────────────

// 方向顏色常數
const _cwColor = Color(0xFFFF9800); // 順時鐘：橘色
const _ccwColor = Color(0xFF42A5F5); // 逆時鐘：藍色

/// 建構魚骨圖的標題資料。
///
/// [colors] 色彩方案，[laps] 圈數資料，[maxY] Y 軸最大值。
FlTitlesData buildFishboneTitlesData(
  ColorScheme colors,
  List<LapSummary> laps,
  double maxY,
) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    // 左側 Y 軸：正負值都顯示（轉成絕對值）
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        getTitlesWidget: (value, meta) {
          // 顯示絕對值
          final absValue = value.abs();
          return Text(
            '${absValue.toStringAsFixed(0)}s',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
            textAlign: TextAlign.right,
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 36,
        interval: calculateLapLabelInterval(laps.length),
        getTitlesWidget: (value, meta) {
          final v = value.toInt();
          final lap = laps.where((l) => l.lapIndex == v).firstOrNull;
          final isClockwise = lap?.isClockwise ?? false;
          final isCounterclockwise = lap?.isCounterclockwise ?? false;
          final dirColor = isClockwise
              ? _cwColor
              : (isCounterclockwise ? _ccwColor : colors.onSurfaceVariant);

          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'L$v',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                // 顏色標記
                Container(
                  width: 16,
                  height: 3,
                  decoration: BoxDecoration(
                    color: dirColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// 建構魚骨圖的 BarChartGroupData。
///
/// [lap] 單圈資料，[vm] ViewModel，[displayedStages] 要顯示的階段列表，
/// [isSelected] 是否為選中的圈數，[chartMaxY] 圖表 Y 軸最大值，
/// [colors] 色彩方案，[isDark] 是否為深色模式。
BarChartGroupData buildFishboneLapGroup({
  required LapSummary lap,
  required StageDurationsOverviewViewModel vm,
  required List<String> displayedStages,
  required bool isSelected,
  required double chartMaxY,
  required ColorScheme colors,
  required bool isDark,
}) {
  final isClockwise = lap.isClockwise;
  final isCounterclockwise = lap.isCounterclockwise;
  // 順時鐘往上（正值），逆時鐘往下（負值）
  final direction = isClockwise ? 1.0 : (isCounterclockwise ? -1.0 : 1.0);
  // 順時鐘橘色、逆時鐘藍色
  final directionColor = isClockwise ? _cwColor : _ccwColor;

  final isHighlighted = vm.isHighlightedByLapIndex[lap.lapIndex] ?? true;
  final dim = vm.dimNonMatching && !isHighlighted;

  final hasFilter =
      vm.highlightRangePct.start > 0 || vm.highlightRangePct.end < 100;
  final showSelectedBorder = isSelected && !hasFilter;

  var acc = 0.0;
  final items = <BarChartRodStackItem>[];

  for (var i = 0; i < displayedStages.length; i++) {
    final label = displayedStages[i];
    final value = lap.stages
        .where((s) => s.label == label)
        .fold<double>(0, (sum, s) => sum + s.durationSeconds);
    if (value <= 0) continue;

    final originalIndex = vm.stageLabels.indexOf(label);
    final colorIndex = originalIndex >= 0 ? originalIndex : i;
    final base = stageDurationPalette[colorIndex % stageDurationPalette.length];

    final color =
        dim ? dimStageColor(base: base, scheme: colors, isDark: isDark) : base;

    // 根據方向決定堆疊方向
    if (direction > 0) {
      items.add(BarChartRodStackItem(acc, acc + value, color));
    } else {
      items.add(BarChartRodStackItem(-(acc + value), -acc, color));
    }
    acc += value;
  }

  final toY = direction > 0 ? acc : -acc;

  final rod = BarChartRodData(
    fromY: 0,
    toY: toY,
    width: 22,
    borderRadius: direction > 0
        ? const BorderRadius.vertical(top: Radius.circular(6))
        : const BorderRadius.vertical(bottom: Radius.circular(6)),
    rodStackItems: items,
    backDrawRodData: BackgroundBarChartRodData(
      show: showSelectedBorder,
      color: directionColor.withValues(alpha: 0.15),
      fromY: 0,
      toY: direction > 0 ? chartMaxY : -chartMaxY,
    ),
    borderSide: showSelectedBorder
        ? BorderSide(color: directionColor, width: 2)
        : BorderSide.none,
  );

  return BarChartGroupData(
    x: lap.lapIndex,
    barRods: [rod],
    showingTooltipIndicators: const [],
  );
}
