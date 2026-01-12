import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/chart_dots.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import 'chart_components.dart';
import 'chart_utils.dart';

/// θ(t) 骨盆朝向角度圖表。
class ThetaChart extends StatelessWidget {
  const ThetaChart({
    required this.lap,
    required this.showSamples,
    required this.sampleLimit,
    required this.maxPoints,
    super.key,
  });

  final PerLapOffsetLap lap;
  final bool showSamples;
  final int? sampleLimit;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    final time = lap.timeSeconds;
    final theta = lap.thetaDegrees;
    if (time.isEmpty || theta.isEmpty) {
      return const LapChartCard(
        title: 'θ(t)',
        subtitle: '圈起始為 0° 的骨盆朝向',
        reserveLegendSpace: true,
        child: EmptyChartMessage('缺少 θ(t) 資料'),
      );
    }

    final unlimitSamples = showSamples && sampleLimit == null;
    final spots = buildSpots(
      time,
      theta,
      maxPoints: unlimitSamples ? time.length : maxPoints,
    );
    final sampleSpots = showSamples ? limitFlSpots(spots, sampleLimit) : null;
    final yRange = computeRange(theta);
    final padding = yRange.delta == 0 ? 5 : yRange.delta * 0.15;

    final annotations = buildRegionAnnotations(
      time,
      lap,
      turnColor: const Color(0xFF95B7FF).withValues(alpha: 0.24),
    );

    final showStroke = shouldShowDotStroke(
      sampleLimit: sampleLimit,
      spots: sampleSpots,
    );

    return LapChartCard(
      title: 'θ(t)',
      subtitle: '圈起始為 0° 的骨盆朝向',
      reserveLegendSpace: true,
      child: LineChart(
        LineChartData(
          minX: time.first,
          maxX: time.last,
          minY: yRange.min - padding,
          maxY: yRange.max + padding,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.black.withValues(alpha: 0.7),
              getTooltipItems: _buildTooltipItems,
            ),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            horizontalInterval: gridInterval(
              yRange.min - padding,
              yRange.max + padding,
              fallback: 10,
            ),
            getDrawingHorizontalLine: (value) => FlLine(
              color:
                  colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: _buildBorderData(colors, isDark),
          titlesData: buildChartTitles(
            context,
            bottomLabel: '時間 (s)',
            leftFormatter: (value) => value.toStringAsFixed(0),
          ),
          rangeAnnotations: RangeAnnotations(
            verticalRangeAnnotations: annotations,
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: const Color(0xFF60A5FA),
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
            if (sampleSpots != null)
              LineChartBarData(
                spots: sampleSpots,
                isCurved: false,
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF60A5FA),
                    strokeWidth: showStroke ? 1 : 0,
                    strokeColor: showStroke
                        ? (isDark ? Colors.black : Colors.white)
                        : Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<LineTooltipItem?> _buildTooltipItems(List<LineBarSpot> spots) {
    final items = <LineTooltipItem?>[];
    var shown = false;
    for (final spot in spots) {
      if (shown || spot.bar.barWidth == 0) {
        items.add(null);
        continue;
      }
      items.add(
        LineTooltipItem(
          '${spot.y.toStringAsFixed(1)}° @ ${spot.x.toStringAsFixed(2)} s',
          const TextStyle(fontSize: 11, color: Colors.white),
        ),
      );
      shown = true;
    }
    return items;
  }

  FlBorderData _buildBorderData(ColorScheme colors, bool isDark) {
    return FlBorderData(
      show: true,
      border: Border(
        left: BorderSide(
          color: colors.onSurface.withValues(alpha: isDark ? 0.24 : 0.18),
        ),
        bottom: BorderSide(
          color: colors.onSurface.withValues(alpha: isDark ? 0.24 : 0.18),
        ),
        right: const BorderSide(color: Colors.transparent),
        top: const BorderSide(color: Colors.transparent),
      ),
    );
  }
}
