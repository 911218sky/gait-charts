import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/chart_dots.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import 'chart_components.dart';
import 'chart_utils.dart';

/// Lateral offset 時序圖，顯示原始與平滑後的偏移曲線。
class LatSeriesChart extends StatelessWidget {
  const LatSeriesChart({
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
    if (time.isEmpty || lap.latSmooth.isEmpty) {
      return const LapChartCard(
        title: 'lat(t)',
        subtitle: '原始與平滑後 lateral offset',
        child: EmptyChartMessage('缺少 lateral offset 資料'),
      );
    }

    final unlimitSamples = showSamples && sampleLimit == null;
    final rawSpots = buildSpots(
      time,
      lap.latRaw,
      maxPoints: unlimitSamples ? time.length : maxPoints,
    );
    final smoothSpots = buildSpots(
      time,
      lap.latSmooth,
      maxPoints: unlimitSamples ? time.length : maxPoints,
    );
    final yRange = computeRange([...lap.latRaw, ...lap.latSmooth]);
    final padding = yRange.delta == 0 ? 0.5 : yRange.delta * 0.1;
    final minY = yRange.min - padding;
    final maxY = yRange.max + padding;

    final annotations = buildRegionAnnotations(
      time,
      lap,
      turnColor: const Color(0xFF95B7FF).withValues(alpha: 0.24),
    );
    final rawSampleSpots =
        showSamples ? limitFlSpots(rawSpots, sampleLimit) : null;
    final smoothSampleSpots =
        showSamples ? limitFlSpots(smoothSpots, sampleLimit) : null;
    final showRawStroke = shouldShowDotStroke(
      sampleLimit: sampleLimit,
      spots: rawSampleSpots,
    );
    final showSmoothStroke = shouldShowDotStroke(
      sampleLimit: sampleLimit,
      spots: smoothSampleSpots,
    );

    return LapChartCard(
      title: 'lat(t)',
      subtitle: '原始 vs 平滑後偏移',
      legend: const [
        LegendEntry(label: 'Raw', color: Color(0xFF78A1FF)),
        LegendEntry(label: 'Smooth', color: Color(0xFF4ADE80)),
      ],
      child: LineChart(
        LineChartData(
          minX: time.first,
          maxX: time.last,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.black.withValues(alpha: 0.7),
              getTooltipItems: _buildTooltipItems,
            ),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: gridInterval(minY, maxY, fallback: 0.2),
            getDrawingHorizontalLine: (value) => FlLine(
              color:
                  colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
              strokeWidth: 1,
            ),
          ),
          borderData: _buildBorderData(colors, isDark),
          titlesData: buildChartTitles(
            context,
            bottomLabel: '時間 (s)',
            leftFormatter: (value) => value.toStringAsFixed(1),
          ),
          rangeAnnotations: RangeAnnotations(
            verticalRangeAnnotations: annotations,
          ),
          lineBarsData: [
            _buildLineBar(rawSpots, const Color(0xFF78A1FF), 1.5),
            _buildLineBar(smoothSpots, const Color(0xFF4ADE80), 2.5),
            if (rawSampleSpots != null)
              _buildDotBar(
                rawSampleSpots,
                const Color(0xFF78A1FF),
                showRawStroke,
                isDark,
              ),
            if (smoothSampleSpots != null)
              _buildDotBar(
                smoothSampleSpots,
                const Color(0xFF4ADE80),
                showSmoothStroke,
                isDark,
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
          '${spot.y.toStringAsFixed(2)} m @ ${spot.x.toStringAsFixed(2)} s',
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

  LineChartBarData _buildLineBar(List<FlSpot> spots, Color color, double width) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: color,
      barWidth: width,
      dotData: const FlDotData(show: false),
    );
  }

  LineChartBarData _buildDotBar(
    List<FlSpot> spots,
    Color color,
    bool showStroke,
    bool isDark,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: false,
      color: Colors.transparent,
      barWidth: 0,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: showStroke ? 1 : 0,
          strokeColor: showStroke
              ? (isDark ? Colors.black : Colors.white)
              : Colors.transparent,
        ),
      ),
    );
  }
}
