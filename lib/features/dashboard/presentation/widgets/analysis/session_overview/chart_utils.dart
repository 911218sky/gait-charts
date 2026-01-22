import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

// ─────────────────────────────────────────────────────────────
// Tooltip 狀態
// ─────────────────────────────────────────────────────────────

/// Tooltip 狀態，用於追蹤目前顯示的 tooltip 位置與對應的圈數。
class TooltipState {
  const TooltipState({required this.lapIndex, required this.position});

  /// 對應的圈數索引。
  final int lapIndex;

  /// Tooltip 顯示位置。
  final Offset position;
}

// ─────────────────────────────────────────────────────────────
// 共用工具函數
// ─────────────────────────────────────────────────────────────

/// 將階段顏色變暗（用於未命中的圈數）。
///
/// [base] 原始顏色，[scheme] 色彩方案，[isDark] 是否為深色模式。
Color dimStageColor({
  required Color base,
  required ColorScheme scheme,
  required bool isDark,
}) {
  final target =
      isDark ? scheme.surfaceContainerHighest : scheme.surfaceContainerHigh;
  final mixed = Color.lerp(base, target, isDark ? 0.72 : 0.62) ?? base;
  return mixed.withValues(alpha: isDark ? 0.62 : 0.52);
}

/// 計算圖表 Y 軸最大值。
///
/// 根據 [laps] 中各圈的階段耗時計算最大值，
/// 若有指定 [displayedStages] 則只計算這些階段的總和。
double calculateMaxY(List<LapSummary> laps, List<String> displayedStages) {
  var maxTotal = 0.0;
  for (final lap in laps) {
    final total = lap.totalDurationSeconds <= 0
        ? lap.stages.fold<double>(0, (sum, s) => sum + s.durationSeconds)
        : lap.totalDurationSeconds;
    if (displayedStages.length == lap.stages.length) {
      maxTotal = math.max(maxTotal, total);
      continue;
    }
    final selected = lap.stages
        .where((s) => displayedStages.contains(s.label))
        .fold<double>(0, (sum, s) => sum + s.durationSeconds);
    maxTotal = math.max(maxTotal, selected);
  }
  return maxTotal <= 0 ? 1.0 : maxTotal;
}

/// 計算圈數標籤間隔。
///
/// 根據圈數 [count] 決定適當的標籤顯示間隔，避免標籤過於擁擠。
double calculateLapLabelInterval(int count) {
  if (count <= 0) return 1;
  if (count <= 14) return 1;
  if (count <= 28) return 2;
  if (count <= 50) return 4;
  return 6;
}
