import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';

/// 將資料轉換為 FL Chart 的 points，並依 maxPoints 下採樣。
List<FlSpot> buildSpots(
  List<double> xs,
  List<double> ys, {
  required int maxPoints,
  double yScale = 1,
  double yOffset = 0,
}) {
  final length = math.min(xs.length, ys.length);
  if (length == 0) return const <FlSpot>[];

  final step = math.max(1, (length / maxPoints).ceil());
  final spots = <FlSpot>[];
  for (var i = 0; i < length; i += step) {
    final x = xs[i];
    final y = (ys[i] - yOffset) * yScale;
    if (x.isFinite && y.isFinite) {
      spots.add(FlSpot(x, y));
    }
  }
  // 確保最後一點也被包含
  if ((length - 1) % step != 0) {
    final x = xs[length - 1];
    final y = (ys[length - 1] - yOffset) * yScale;
    if (x.isFinite && y.isFinite) {
      spots.add(FlSpot(x, y));
    }
  }
  return spots;
}

/// 依據資料範圍自動選擇「漂亮」的刻度間距（1/2/5/10 * 10^n）。
double gridInterval(
  double min,
  double max, {
  required double fallback,
  int targetLines = 6,
}) {
  if (!min.isFinite || !max.isFinite) return fallback;

  final span = (max - min).abs();
  if (span <= 0 || !span.isFinite) return fallback;

  final safeTarget = targetLines <= 0 ? 6 : targetLines;
  final raw = span / safeTarget;
  if (raw <= 0 || !raw.isFinite) return fallback;

  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
  final normalized = raw / magnitude;
  double interval;
  if (normalized < 1.5) {
    interval = 1;
  } else if (normalized < 3) {
    interval = 2;
  } else if (normalized < 7) {
    interval = 5;
  } else {
    interval = 10;
  }
  final result = interval * magnitude.toDouble();
  if (!result.isFinite || result <= 0) return fallback;

  // fallback 同時扮演「最小可接受刻度」
  return result < fallback ? fallback : result;
}

double floorToInterval(double value, double interval) {
  if (!value.isFinite || !interval.isFinite || interval <= 0) return value;
  return (value / interval).floorToDouble() * interval;
}

double ceilToInterval(double value, double interval) {
  if (!value.isFinite || !interval.isFinite || interval <= 0) return value;
  return (value / interval).ceilToDouble() * interval;
}

/// 將 FlSpots 依 limit 再次下採樣。
List<FlSpot> limitFlSpots(List<FlSpot> spots, int? limit) {
  if (limit == null || spots.length <= limit) return spots;

  final step = (spots.length / limit).ceil();
  final limited = <FlSpot>[];
  for (var i = 0; i < spots.length; i += step) {
    limited.add(spots[i]);
  }
  if ((spots.length - 1) % step != 0) {
    limited.add(spots.last);
  }
  return limited;
}
