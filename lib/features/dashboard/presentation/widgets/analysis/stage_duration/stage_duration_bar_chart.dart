import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import 'stage_duration_palette.dart';

/// 呈現單圈階段耗時的柱狀圖。
class StageDurationBarChart extends StatefulWidget {
  const StageDurationBarChart({
    required this.stages,
    required this.totalDurationSeconds,
    super.key,
    this.height = 340,
  });

  final List<StageDurationStage> stages;
  final double totalDurationSeconds;
  final double height;

  @override
  State<StageDurationBarChart> createState() => _StageDurationBarChartState();
}

class _StageDurationBarChartState extends State<StageDurationBarChart> {
  _TooltipState? _tooltip;

  int _fractionDigitsForInterval(double interval) {
    if (interval >= 1) return 0;
    if (interval >= 0.2) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final stages = widget.stages;
    final totalDuration = widget.totalDurationSeconds > 0
        ? widget.totalDurationSeconds
        : stages.fold<double>(0, (sum, stage) => sum + stage.durationSeconds);
    final maxValue = stages.fold<double>(
      0,
      (previousValue, element) => element.durationSeconds > previousValue
          ? element.durationSeconds
          : previousValue,
    );
    // `BarChartData.maxY` 需要 double；避免 `?:` 產生 num。
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.4;
    final yInterval = (maxY / 8).clamp(0.1, 5.0).toDouble();
    final yLabelDigits = _fractionDigitsForInterval(yInterval);

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
          final tooltip = _tooltip;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: EdgeInsets.zero,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem('', const TextStyle()),
                    ),
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        setState(() => _tooltip = null);
                        return;
                      }

                      final groupIndex = response.spot!.touchedBarGroupIndex;
                      if (groupIndex < 0 || groupIndex >= stages.length) {
                        return;
                      }
                      final stage = stages[groupIndex];
                      final localPos = event.localPosition ?? Offset.zero;
                      final ratio = totalDuration <= 0
                          ? 0.0
                          : (stage.durationSeconds / totalDuration).clamp(
                              0.0,
                              1.0,
                            );

                      setState(() {
                        _tooltip = _TooltipState(
                          stage: stage,
                          position: localPos,
                          ratio: ratio,
                        );
                      });
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: colors.onSurface.withValues(alpha: 0.18)),
                      bottom: BorderSide(color: colors.onSurface.withValues(alpha: 0.18)),
                      right: const BorderSide(color: Colors.transparent),
                      top: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: true,
                    // 讓網格與 Y 軸標籤使用同一個 interval，避免刻度/文字不對齊。
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
                      strokeWidth: 1,
                    ),
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) => Text(
                          // 避免 interval < 1 時四捨五入造成「重複數字」。
                          value.toStringAsFixed(yLabelDigits),
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < stages.length; i++)
                      _buildBar(stage: stages[i], index: i),
                  ],
                ),
              ),
              if (tooltip != null)
                Positioned(
                  left: (tooltip.position.dx - 90).clamp(
                    0.0,
                    chartSize.width - 180,
                  ),
                  top: (tooltip.position.dy - 120).clamp(
                    0.0,
                    chartSize.height - 140,
                  ),
                  child: DashboardGlassTooltip(
                    child: _StageTooltipContent(
                      stage: tooltip.stage,
                      ratio: tooltip.ratio,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  BarChartGroupData _buildBar({
    required StageDurationStage stage,
    required int index,
  }) {
    final distance = stage.distanceMeters;
    final baseColor = stageDurationPalette[index % stageDurationPalette.length];
    final color = distance != null
        ? baseColor.withValues(alpha: (0.35 + (distance / 10)).clamp(0.35, 0.8))
        : baseColor.withValues(alpha: 0.45);

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: stage.durationSeconds,
          width: 26,
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [color, baseColor],
          ),
          backDrawRodData: BackgroundBarChartRodData(show: false),
        ),
      ],
      showingTooltipIndicators: const [0],
    );
  }
}

/// 記錄 tooltip 所需狀態。
class _TooltipState {
  _TooltipState({
    required this.stage,
    required this.position,
    required this.ratio,
  });

  final StageDurationStage stage;
  final Offset position;
  final double ratio;
}

class _StageTooltipContent extends StatelessWidget {
  const _StageTooltipContent({required this.stage, required this.ratio});

  final StageDurationStage stage;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final distance = stage.distanceMeters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${stage.durationSeconds.toStringAsFixed(2)} 秒',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        if (distance != null) ...[
          const SizedBox(height: 4),
          Text(
            '距離 ${distance.toStringAsFixed(2)} m',
            style: TextStyle(
              color: colors.primary.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          stage.label,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.72),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '佔比 ${(ratio * 100).clamp(0.0, 100.0).toStringAsFixed(0)}%',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.62),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
