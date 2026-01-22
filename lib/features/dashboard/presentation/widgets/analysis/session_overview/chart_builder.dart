import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/session_overview/chart_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/analysis/stage_duration/stage_duration_palette.dart';

// ─────────────────────────────────────────────────────────────
// 圖表建構工具
// ─────────────────────────────────────────────────────────────

/// 圖表建構工具類別。
///
/// 提供建構 Session Overview 圖表所需的靜態方法，
/// 包含 bar group 建構和軸標題資料建構。
class ChartBuilder {
  const ChartBuilder._();

  // 方向顏色常數
  static const _cwColor = Color(0xFFFF9800); // 順時鐘：橘色
  static const _ccwColor = Color(0xFF42A5F5); // 逆時鐘：藍色

  /// 建構單圈的 BarChartGroupData。
  ///
  /// [lap] 單圈資料，[vm] ViewModel，[displayedStages] 要顯示的階段列表，
  /// [isSelected] 是否為選中的圈數，[chartMaxY] 圖表 Y 軸最大值，
  /// [colors] 色彩方案，[isDark] 是否為深色模式。
  static BarChartGroupData buildLapGroup({
    required LapSummary lap,
    required StageDurationsOverviewViewModel vm,
    required List<String> displayedStages,
    required bool isSelected,
    required double chartMaxY,
    required ColorScheme colors,
    required bool isDark,
  }) {
    final total = lap.totalDurationSeconds <= 0
        ? lap.stages.fold<double>(0, (sum, s) => sum + s.durationSeconds)
        : lap.totalDurationSeconds;

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
      final base =
          stageDurationPalette[colorIndex % stageDurationPalette.length];

      final color = dim
          ? dimStageColor(base: base, scheme: colors, isDark: isDark)
          : base;

      items.add(BarChartRodStackItem(acc, acc + value, color));
      acc += value;
    }

    final rod = BarChartRodData(
      toY: acc <= 0 ? total : acc,
      width: 22,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      rodStackItems: items,
      backDrawRodData: BackgroundBarChartRodData(
        show: showSelectedBorder,
        color: colors.primary.withValues(alpha: 0.1),
        toY: chartMaxY,
      ),
      borderSide: showSelectedBorder
          ? BorderSide(color: colors.primary, width: 2)
          : BorderSide.none,
    );

    return BarChartGroupData(
      x: lap.lapIndex,
      barRods: [rod],
      showingTooltipIndicators: const [],
    );
  }

  /// 建構 X/Y 軸標題資料。
  ///
  /// [colors] 色彩方案，[lapCount] 圈數總數，
  /// [laps] 圈數資料（用於顯示方向標記），
  /// [showDirectionIcon] 是否顯示方向標記。
  static FlTitlesData buildTitlesData(
    ColorScheme colors,
    int lapCount, {
    List<LapSummary>? laps,
    bool showDirectionIcon = false,
  }) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) => Text(
            '${value.toStringAsFixed(0)}s',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
            textAlign: TextAlign.right,
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: showDirectionIcon ? 36 : 28,
          interval: calculateLapLabelInterval(lapCount),
          getTitlesWidget: (value, meta) {
            final v = value.toInt();
            // 找到對應的 lap 來顯示方向
            final lap = laps?.where((l) => l.lapIndex == v).firstOrNull;
            final isClockwise = lap?.isClockwise ?? false;
            final isCounterclockwise = lap?.isCounterclockwise ?? false;
            final hasDirection = isClockwise || isCounterclockwise;
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
                  if (showDirectionIcon && hasDirection) ...[
                    const SizedBox(height: 2),
                    // 顏色條標記
                    Container(
                      width: 16,
                      height: 3,
                      decoration: BoxDecoration(
                        color: dirColor,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
