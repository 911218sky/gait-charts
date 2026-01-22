import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 熱圖色階計算工具。
///
/// 根據 min/max 範圍將數值映射到調色盤顏色。
class HeatmapColorScale {
  const HeatmapColorScale({
    required this.min,
    required this.max,
    required this.palette,
  });

  final double? min;
  final double? max;
  final DashboardHeatmapPalette palette;

  /// 根據數值取得對應顏色。
  Color? colorFor(double value) {
    if (min == null || max == null) {
      return null;
    }
    final domain = max! - min!;
    if (domain.abs() < 1e-6) {
      return palette.colorAt(0.5);
    }
    final t = ((value - min!) / domain).clamp(0.0, 1.0);
    return palette.colorAt(t);
  }
}
