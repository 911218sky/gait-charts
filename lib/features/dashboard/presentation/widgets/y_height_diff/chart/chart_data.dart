import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/chart/chart_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/chart/height_unit.dart';

/// 圖表資料系列。
class ChartSeries {
  const ChartSeries({
    required this.label,
    required this.color,
    required this.spots,
  });

  final String label;
  final Color color;
  final List<FlSpot> spots;
}

/// Tooltip 顯示資料。
class ChartTooltipData {
  ChartTooltipData({
    required this.time,
    required this.values,
    required this.position,
  });

  final double time;
  final Map<String, double> values;
  final Offset position;
}

/// Brush 選取區域。
class BrushRect {
  const BrushRect({required this.left, required this.width});
  final double left;
  final double width;
}

/// 高度差圖表的預處理資料。
class YHeightChartData {
  YHeightChartData({
    required this.series,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.paddingY,
    required this.yInterval,
    required this.length,
  });

  final List<ChartSeries> series;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double paddingY;
  final double yInterval;
  final int length;

  bool get hasEnoughPoints => length >= 2;

  YHeightChartData applyView(RangeValues? view) {
    if (view == null || view.end - view.start <= 0) {
      return this;
    }
    final filteredSeries = series
        .map(
          (s) => ChartSeries(
            label: s.label,
            color: s.color,
            spots: s.spots
                .where((p) => p.x >= view.start && p.x <= view.end)
                .toList(),
          ),
        )
        .toList();
    final allY = filteredSeries.expand((s) => s.spots.map((p) => p.y)).toList();
    if (allY.isEmpty) {
      return this;
    }
    final minY = allY.reduce(math.min);
    final maxY = allY.reduce(math.max);
    final padding = (maxY - minY) * 0.1;
    return YHeightChartData(
      series: filteredSeries,
      minX: view.start,
      maxX: view.end,
      minY: minY,
      maxY: maxY,
      paddingY: padding,
      yInterval: yInterval,
      length: filteredSeries.fold<int>(0, (sum, s) => sum + s.spots.length),
    );
  }

  factory YHeightChartData.fromResponse(
    YHeightDiffResponse response,
    DashboardAccentColors accent, {
    required int maxPoints,
    required HeightUnit unit,
    required bool showDiff,
  }) {
    final yScale = unit.yScale;
    final spots = buildSpots(
      response.timeSeconds,
      response.left,
      maxPoints: maxPoints,
      yScale: yScale,
    );
    if (spots.length < 2) {
      return YHeightChartData(
        series: const [],
        minX: 0,
        maxX: 0,
        minY: 0,
        maxY: 0,
        paddingY: 0,
        yInterval: 1,
        length: spots.length,
      );
    }

    final series = [
      ChartSeries(label: 'Left', color: accent.success, spots: spots),
      ChartSeries(
        label: 'Right',
        color: accent.warning,
        spots: buildSpots(
          response.timeSeconds,
          response.right,
          maxPoints: maxPoints,
          yScale: yScale,
        ),
      ),
      if (showDiff)
        ChartSeries(
          label: 'Diff (L-R)',
          color: accent.danger,
          spots: buildSpots(
            response.timeSeconds,
            response.diff,
            maxPoints: maxPoints,
            yScale: yScale,
          ),
        ),
    ];

    var minY = series.first.spots.first.y;
    var maxY = minY;
    for (final s in series) {
      for (final point in s.spots) {
        final y = point.y;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
    final span = (maxY - minY).abs();
    // 曲線幾乎水平時給合理的最小 padding
    final paddingY = span < 1e-6
        ? (unit == HeightUnit.cm ? 5.0 : 0.05)
        : span * 0.1;

    final yInterval = gridInterval(
      minY - paddingY,
      maxY + paddingY,
      fallback: unit == HeightUnit.cm ? 1 : 0.01,
      targetLines: 10,
    );

    return YHeightChartData(
      series: series,
      minX: response.timeSeconds.first,
      maxX: response.timeSeconds.isNotEmpty
          ? response.timeSeconds.last
          : series.first.spots.last.x,
      minY: minY,
      maxY: maxY,
      paddingY: paddingY,
      yInterval: yInterval,
      length: series.isEmpty ? 0 : series.first.spots.length,
    );
  }
}
