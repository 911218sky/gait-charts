import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// 數值範圍統計。
class RangeStats {
  const RangeStats(this.min, this.max);

  final double min;
  final double max;

  double get delta => max - min;
}

/// 計算數值列表的最小/最大範圍。
RangeStats computeRange(List<double> values) {
  if (values.isEmpty) {
    return const RangeStats(0, 0);
  }
  var minValue = double.infinity;
  var maxValue = -double.infinity;
  for (final value in values) {
    if (!value.isFinite) continue;
    if (value < minValue) minValue = value;
    if (value > maxValue) maxValue = value;
  }
  if (!minValue.isFinite || !maxValue.isFinite) {
    return const RangeStats(0, 0);
  }
  return RangeStats(minValue, maxValue);
}

/// 計算適合的網格間距。
double gridInterval(
  double min,
  double max, {
  double fallback = 1,
  int targetLines = 8,
}) {
  final delta = (max - min).abs();
  if (delta <= 0) return fallback;
  final step = delta / targetLines;
  if (step <= 0) return fallback;
  final magnitude = math.pow(10, step.log10().floor()).toDouble();
  final normalized = (step / magnitude).ceil();
  return math.max(fallback, normalized * magnitude);
}

extension Log10Extension on double {
  double log10() => math.log(this) / math.ln10;
}

/// 建立圖表軸標題配置。
FlTitlesData buildChartTitles(
  BuildContext context, {
  required String bottomLabel,
  required String Function(double) leftFormatter,
}) {
  final colors = context.colorScheme;
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      axisNameWidget: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(
          bottomLabel,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
      ),
      sideTitles: SideTitles(
        showTitles: true,
        interval: null,
        getTitlesWidget: (value, meta) => Text(
          value.abs() >= 10
              ? value.toStringAsFixed(0)
              : value.toStringAsFixed(1),
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
        reservedSize: 40,
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            leftFormatter(value),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ),
        reservedSize: 40,
      ),
    ),
  );
}

/// 建立圈數區域標註（轉彎區段）。
List<VerticalRangeAnnotation> buildRegionAnnotations(
  List<double> times,
  PerLapOffsetLap lap, {
  required Color turnColor,
}) {
  VerticalRangeAnnotation? build(LapRegion region, Color color) {
    if (times.isEmpty || !region.isValid) return null;
    final startIndex = region.startIndex.clamp(0, times.length - 1);
    final endIndex = region.endIndex.clamp(0, times.length - 1);
    if (endIndex <= startIndex) return null;
    final x1 = times[startIndex];
    final x2 = times[endIndex];
    if ((x2 - x1).abs() <= 0) return null;
    return VerticalRangeAnnotation(x1: x1, x2: x2, color: color);
  }

  final annotations = <VerticalRangeAnnotation>[];
  void addRegion(LapRegion region, Color color) {
    final annotation = build(region, color);
    if (annotation != null) annotations.add(annotation);
  }

  addRegion(lap.coneTurn, turnColor);
  addRegion(lap.chairTurn, turnColor);
  return annotations;
}

/// 建立圖表資料點，支援降採樣。
List<FlSpot> buildSpots(
  List<double> xs,
  List<double> ys, {
  int maxPoints = 800,
}) {
  final length = math.min(xs.length, ys.length);
  if (length == 0) return const <FlSpot>[];

  final step = math.max(1, (length / maxPoints).ceil());
  final spots = <FlSpot>[];
  for (var i = 0; i < length; i += step) {
    final x = xs[i];
    final y = ys[i];
    if (x.isFinite && y.isFinite) spots.add(FlSpot(x, y));
  }
  // 確保最後一點被包含
  if ((length - 1) % step != 0) {
    final x = xs[length - 1];
    final y = ys[length - 1];
    if (x.isFinite && y.isFinite) spots.add(FlSpot(x, y));
  }
  return spots;
}

/// 限制 FlSpot 列表的點數。
List<FlSpot> limitFlSpots(List<FlSpot> spots, int? limit) {
  if (limit == null || spots.length <= limit) return spots;

  final step = (spots.length / limit).ceil();
  final limited = <FlSpot>[];
  for (var i = 0; i < spots.length; i += step) {
    limited.add(spots[i]);
  }
  if ((spots.length - 1) % step != 0) limited.add(spots.last);
  return limited;
}
