import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/benchmark_radar.dart';

// ─────────────────────────────────────────────────────────────
// Functional Assessment 常數
// ─────────────────────────────────────────────────────────────

const List<String> enduranceOrder = [
  'walk_to_cone_s',
  'walk_back_and_sit_s',
  'total_walking_s',
];

const Map<String, String> enduranceLabels = {
  'walk_to_cone_s': '走向角錐',
  'walk_back_and_sit_s': '走回+坐下',
  'total_walking_s': '總行走時間',
};

const List<String> balanceOrder = [
  'cone_turn_s',
];

const Map<String, String> balanceLabels = {
  'cone_turn_s': '三角錐轉身',
};

const List<String> muscleEnduranceOrder = [
  'stand_up_s',
  'return_and_sit_s',
];

const Map<String, String> muscleEnduranceLabels = {
  'stand_up_s': '站起時間',
  'return_and_sit_s': '走回+坐下',
};

// ─────────────────────────────────────────────────────────────
// Lap Time 常數
// ─────────────────────────────────────────────────────────────

const List<String> lapTimeOrder = [
  'dur_total',
  'dur_walking',
  'dur_stand',
  'dur_to_cone',
  'dur_cone_turn',
  'dur_return',
  'dur_turn_to_sit',
  'dur_sit',
];

const Map<String, String> lapTimeLabels = {
  'dur_total': '單圈總時間',
  'dur_walking': '總行走時間',
  'dur_stand': '起身時間',
  'dur_to_cone': '走向錐子（去程）',
  'dur_cone_turn': '錐子轉身',
  'dur_return': '返回（回程）',
  'dur_turn_to_sit': '椅子轉身對位',
  'dur_sit': '坐下時間',
};


// ─────────────────────────────────────────────────────────────
// Gait 常數
// ─────────────────────────────────────────────────────────────

const List<String> gaitOrder = [
  'spm',
  'mean_step_len',
  'l_swing_pct',
  'r_swing_pct',
  'l_stance_s',
  'r_stance_s',
];

const Map<String, String> gaitLabels = {
  'spm': '步頻',
  'mean_step_len': '平均步長',
  'l_swing_pct': '左擺動期%',
  'r_swing_pct': '右擺動期%',
  'l_stance_s': '左支撐期(s)',
  'r_stance_s': '右支撐期(s)',
};

// ─────────────────────────────────────────────────────────────
// Speed & Distance 常數
// ─────────────────────────────────────────────────────────────

const List<String> speedOrder = [
  'speed_mps',
  'dist_lap_path_m',
  'dist_walking_m',
  'dist_outbound_m',
  'dist_return_m',
  'dist_cone_turn_m',
];

const Map<String, String> speedLabels = {
  'speed_mps': '速度(m/s)',
  'dist_lap_path_m': '單圈路徑長(m)',
  'dist_walking_m': '行走總距離(m)',
  'dist_outbound_m': '去程距離(m)',
  'dist_return_m': '回程距離(m)',
  'dist_cone_turn_m': '錐子轉身距離(m)',
};

// ─────────────────────────────────────────────────────────────
// Turn 常數
// ─────────────────────────────────────────────────────────────

const List<String> turnOrder = [
  'delta_theta_cone_deg',
  'delta_theta_chair_deg',
];

const Map<String, String> turnLabels = {
  'delta_theta_cone_deg': '錐子轉身角度(°)',
  'delta_theta_chair_deg': '椅子轉身角度(°)',
};

// ─────────────────────────────────────────────────────────────
// 標籤工具
// ─────────────────────────────────────────────────────────────

/// 狀態標籤簡短版本。
String statusLabelShort(MetricComparisonStatus status) => switch (status) {
      MetricComparisonStatus.similar => '相近',
      MetricComparisonStatus.worse => '較差',
      MetricComparisonStatus.better => '較佳',
    };

// ─────────────────────────────────────────────────────────────
// 差異標籤工具（新 API）
// ─────────────────────────────────────────────────────────────

/// 取得「比族群好/差 X%」標籤。
///
/// 根據 [isBetter] 決定顯示「好」或「差」。
String? diffLabel(MetricComparison c) {
  final pct = c.diffPct.abs();
  if (pct < 0.5) return '與族群相近';
  final betterOrWorse = c.isBetter ? '好' : '差';
  return '比族群$betterOrWorse ${pct.toStringAsFixed(1)}%';
}

/// 取得差異標籤的顏色。
Color diffColor(BuildContext context, MetricComparison c) {
  final colors = Theme.of(context).colorScheme;
  if (c.diffPct.abs() < 0.5) return colors.onSurfaceVariant;
  return c.isBetter ? colors.tertiary : colors.error;
}

// ─────────────────────────────────────────────────────────────
// 資料建構工具
// ─────────────────────────────────────────────────────────────

/// 指標列表項目。
class MetricRow {
  const MetricRow({
    required this.key,
    required this.label,
    required this.comparison,
  });

  final String key;
  final String label;
  final MetricComparison comparison;
}

/// 建立指標列表項目。
List<MetricRow> buildMetricItems(
  Map<String, MetricComparison> map, {
  required List<String> order,
  required Map<String, String> labelMap,
}) {
  final result = <MetricRow>[];
  final seen = <String>{};
  for (final key in order) {
    final comp = map[key];
    if (comp == null) continue;
    seen.add(key);
    result.add(
      MetricRow(key: key, label: labelMap[key] ?? key, comparison: comp),
    );
  }
  for (final entry in map.entries) {
    if (seen.contains(entry.key)) continue;
    result.add(
      MetricRow(
        key: entry.key,
        label: labelMap[entry.key] ?? entry.key,
        comparison: entry.value,
      ),
    );
  }
  return result;
}

/// 建立雷達圖資料項目（新 API：使用 200% 刻度，100% = 族群基準）。
List<BenchmarkRadarEntry> buildRadarEntries(
  BuildContext context,
  String title,
  Map<String, MetricComparison> map,
  List<String> order,
  Map<String, String> labelMap,
) {
  final palette = DashboardBenchmarkCompareColors.of(context);
  final rows = buildMetricItems(map, order: order, labelMap: labelMap);
  return rows
      .map((row) {
        final c = row.comparison;
        final status = c.status;
        final color = switch (status) {
          MetricComparisonStatus.worse => palette.lower,
          MetricComparisonStatus.better => palette.inRange,
          MetricComparisonStatus.similar => palette.higher,
        };
        // 雷達圖使用 200% 刻度：100% = 族群基準
        // userValue / cohortValue * 100 得到百分比
        // 然後映射到 0~1（對應 0%~200%）
        final ratio = c.cohortValue > 0 ? c.userValue / c.cohortValue : 1.0;
        final percentile01 = (ratio / 2).clamp(0.0, 1.0); // 100% -> 0.5, 200% -> 1.0
        final pctDisplay = (ratio * 100).toStringAsFixed(1);
        return BenchmarkRadarEntry(
          key: '$title.${row.key}',
          label: row.label,
          percentile01: percentile01,
          valueText:
              '個人=${c.userValue.toStringAsFixed(3)} · 族群=${c.cohortValue.toStringAsFixed(3)} · ${pctDisplay}%',
          status: status,
          color: color,
        );
      })
      .toList(growable: false);
}

// ─────────────────────────────────────────────────────────────
// Functional Assessment 工具函數
// ─────────────────────────────────────────────────────────────

/// 功能性指標列表項目。
class FunctionalMetricRow {
  const FunctionalMetricRow({
    required this.key,
    required this.label,
    required this.metric,
  });

  final String key;
  final String label;
  final FunctionalMetric metric;
}

/// 建立功能性指標列表項目。
List<FunctionalMetricRow> buildFunctionalMetricItems(
  Map<String, FunctionalMetric> map, {
  required List<String> order,
  required Map<String, String> labelMap,
}) {
  final result = <FunctionalMetricRow>[];
  final seen = <String>{};
  for (final key in order) {
    final metric = map[key];
    if (metric == null) continue;
    seen.add(key);
    result.add(
      FunctionalMetricRow(key: key, label: labelMap[key] ?? key, metric: metric),
    );
  }
  for (final entry in map.entries) {
    if (seen.contains(entry.key)) continue;
    result.add(
      FunctionalMetricRow(
        key: entry.key,
        label: labelMap[entry.key] ?? entry.key,
        metric: entry.value,
      ),
    );
  }
  return result;
}

/// 功能性指標的表現標籤（較佳/正常/較差）。
String functionalPerformanceLabel(FunctionalMetric metric) {
  final score = metric.radarScore;
  if (score > 55) return '較佳';
  if (score < 45) return '較差';
  return '正常';
}

/// 功能性指標的差異標籤（比參考值好/差 X%）。
///
/// 使用後端計算的 [diffFromReferencePct] 和 [higherIsBetter] 來判斷。
String? functionalDiffLabel(FunctionalMetric metric) {
  if (metric.referenceValue <= 0) return null;
  final diffPct = metric.diffFromReferencePct;
  if (diffPct.abs() < 0.5) return '與參考值相近';
  // 根據 higherIsBetter 判斷：
  // - higherIsBetter=true: diffPct > 0 表示「好」
  // - higherIsBetter=false: diffPct < 0 表示「好」
  final isBetter = metric.higherIsBetter ? diffPct > 0 : diffPct < 0;
  final betterOrWorse = isBetter ? '好' : '差';
  return '比參考值$betterOrWorse ${diffPct.abs().toStringAsFixed(1)}%';
}

/// 功能性指標的比較狀態。
MetricComparisonStatus functionalStatus(FunctionalMetric metric) {
  final score = metric.radarScore;
  if (score > 55) return MetricComparisonStatus.better;
  if (score < 45) return MetricComparisonStatus.worse;
  return MetricComparisonStatus.similar;
}
