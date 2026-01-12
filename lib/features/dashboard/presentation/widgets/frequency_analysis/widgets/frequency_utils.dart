import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';

/// 將頻率資料轉換為圖表點位，並進行降採樣以維持效能
///
/// [priorityX] 中指定的 X 值會優先保留，確保峰值等重要特徵不因降採樣而遺失
List<FlSpot> buildFrequencySpots(
  List<double> xs,
  List<double> ys, {
  required int maxPoints,
  Iterable<double> priorityX = const [],
}) {
  final count = math.min(xs.length, ys.length);
  if (count == 0) return <FlSpot>[];

  // 資料點數未超過上限，直接返回所有點
  if (count <= maxPoints) {
    return List<FlSpot>.generate(
      count,
      (index) => FlSpot(xs[index].toDouble(), ys[index].toDouble()),
    );
  }

  // 等間隔降採樣
  final step = (count / maxPoints).ceil();
  final spots = <FlSpot>[];
  for (var i = 0; i < count; i += step) {
    spots.add(FlSpot(xs[i].toDouble(), ys[i].toDouble()));
  }

  // 確保最後一個點被包含
  if (spots.last.x != xs[count - 1]) {
    spots.add(FlSpot(xs[count - 1].toDouble(), ys[count - 1].toDouble()));
  }

  // 補回優先保留的 X 值對應點位 (如峰值頻率)
  final indicesToInclude = priorityX
      .where((value) => value.isFinite)
      .map((value) => closestFrequencyIndex(xs, value))
      .whereType<int>()
      .toSet();
  for (final index in indicesToInclude) {
    final spot = FlSpot(xs[index].toDouble(), ys[index].toDouble());
    final exists = spots.any(
      (existing) =>
          (existing.x - spot.x).abs() < 1e-6 &&
          (existing.y - spot.y).abs() < 1e-6,
    );
    if (!exists) spots.add(spot);
  }
  spots.sort((a, b) => a.x.compareTo(b.x));
  return spots;
}

/// 在頻率陣列中尋找最接近目標值的索引
int? closestFrequencyIndex(List<double> xs, double value) {
  if (xs.isEmpty) return null;

  var bestIndex = 0;
  var bestDelta = (xs[0] - value).abs();
  for (var i = 1; i < xs.length; i++) {
    final delta = (xs[i] - value).abs();
    if (delta < bestDelta) {
      bestDelta = delta;
      bestIndex = i;
      if (bestDelta < 1e-9) break;
    }
  }
  return bestIndex;
}

/// 計算圖表網格線的適當間距
double frequencyGridInterval(
  double min,
  double max, {
  double fallback = 1,
  int targetLines = 8,
}) {
  if (!min.isFinite || !max.isFinite) return fallback;

  final span = (max - min).abs();
  if (span <= 0) return fallback;

  final raw = span / targetLines;
  if (raw <= 0) return fallback;

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
  return interval * magnitude.toDouble();
}

/// 頻率系列預設調色盤
List<Color> frequencySeriesPalette() {
  return const [
    Color(0xFF60A5FA), // 藍
    Color(0xFF34D399), // 綠
    Color(0xFFFBBF24), // 黃
    Color(0xFFF472B6), // 粉
    Color(0xFFA78BFA), // 紫
    Color(0xFF38BDF8), // 青
  ];
}

/// 根據系列基色計算峰值標記點的顏色
Color frequencyPeakDotColor(Color base) {
  final hsl = HSLColor.fromColor(base);
  final lighter = hsl.withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0));
  return lighter.toColor();
}

/// 建立頻率分析選項切換 Chip
Widget buildFrequencyToggleChip(
  BuildContext context, {
  required String label,
  required bool selected,
  required VoidCallback onTap,
  Color? accentColor,
  String? tooltip,
}) {
  final colors = context.colorScheme;
  final isDark = context.isDark;
  final color = accentColor ?? DashboardAccentColors.of(context).success;
  final chip = FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    labelStyle: TextStyle(
      fontWeight: FontWeight.w600,
      color: selected ? colors.onSurface : colors.onSurfaceVariant,
      letterSpacing: 0.3,
    ),
    backgroundColor: colors.onSurface.withValues(alpha: 0.04),
    selectedColor: color.withValues(alpha: isDark ? 0.18 : 0.14),
    side: BorderSide(
      color: selected ? color : colors.onSurface.withValues(alpha: isDark ? 0.18 : 0.12),
      width: 1.2,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    pressElevation: 0,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    clipBehavior: Clip.antiAlias,
    surfaceTintColor: Colors.transparent,
  );
  if (tooltip != null) {
    return AppTooltip(message: tooltip, child: chip);
  }
  return chip;
}
