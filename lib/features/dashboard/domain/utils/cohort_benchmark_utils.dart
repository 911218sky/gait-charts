import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/benchmark_radar.dart';

/// UI 顯示用：選擇要查看哪個位數（或平均值）。
enum CohortBenchmarkCompareBasis { p10, p25, p50, p75, p90, mean }

// ─────────────────────────────────────────────────────────────
// Lap Time 常數
// ─────────────────────────────────────────────────────────────

const List<String> lapTimeOrder = [
  'dur_total',
  'dur_stand',
  'dur_to_cone',
  'dur_cone_turn',
  'dur_return',
  'dur_turn_to_sit',
  'dur_sit',
];

const Map<String, String> lapTimeLabels = {
  'dur_total': '單圈總時間',
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
  'dist_outbound_m',
  'dist_return_m',
  'dist_cone_turn_m',
];

const Map<String, String> speedLabels = {
  'speed_mps': '速度(m/s)',
  'dist_lap_path_m': '單圈路徑長(m)',
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
// 數值計算工具
// ─────────────────────────────────────────────────────────────

/// 取得使用者在指定位數的數值。
double userValueForBasis(
  MetricComparison c,
  CohortBenchmarkCompareBasis basis,
) => switch (basis) {
  CohortBenchmarkCompareBasis.p10 => c.userP10,
  CohortBenchmarkCompareBasis.p25 => c.userP25,
  CohortBenchmarkCompareBasis.p50 => c.userP50,
  CohortBenchmarkCompareBasis.p75 => c.userP75,
  CohortBenchmarkCompareBasis.p90 => c.userP90,
  CohortBenchmarkCompareBasis.mean => c.userMean,
};

/// 取得族群基準在指定位數的數值。
double benchmarkValueForBasis(
  MetricComparison c,
  CohortBenchmarkCompareBasis basis,
) => switch (basis) {
  CohortBenchmarkCompareBasis.p10 => c.benchmarkP10,
  CohortBenchmarkCompareBasis.p25 => c.benchmarkP25,
  CohortBenchmarkCompareBasis.p50 => c.benchmarkP50,
  CohortBenchmarkCompareBasis.p75 => c.benchmarkP75,
  CohortBenchmarkCompareBasis.p90 => c.benchmarkP90,
  CohortBenchmarkCompareBasis.mean => c.benchmarkMean,
};

/// 取得使用者在族群中的百分位位置。
double percentilePositionForBasis(
  MetricComparison c,
  CohortBenchmarkCompareBasis basis,
) {
  final d = c.diff;
  final v = switch (basis) {
    CohortBenchmarkCompareBasis.p10 => d?.p10PercentilePosition,
    CohortBenchmarkCompareBasis.p25 => d?.p25PercentilePosition,
    CohortBenchmarkCompareBasis.p50 =>
      (d?.p50PercentilePosition ?? c.percentilePosition),
    CohortBenchmarkCompareBasis.p75 => d?.p75PercentilePosition,
    CohortBenchmarkCompareBasis.p90 => d?.p90PercentilePosition,
    CohortBenchmarkCompareBasis.mean => d?.meanPercentilePosition,
  };
  return (v ?? c.percentilePosition).clamp(0.0, 100.0);
}

/// 取得與族群基準的差異百分比。
double? diffPctForBasis(
  MetricComparison c,
  CohortBenchmarkCompareBasis basis,
) {
  final d = c.diff;
  if (d == null) return null;
  return switch (basis) {
    CohortBenchmarkCompareBasis.p10 => d.p10DiffPct,
    CohortBenchmarkCompareBasis.p25 => d.p25DiffPct,
    CohortBenchmarkCompareBasis.p50 => d.p50DiffPct,
    CohortBenchmarkCompareBasis.p75 => d.p75DiffPct,
    CohortBenchmarkCompareBasis.p90 => d.p90DiffPct,
    CohortBenchmarkCompareBasis.mean => d.meanDiffPct,
  };
}


// ─────────────────────────────────────────────────────────────
// 標籤工具
// ─────────────────────────────────────────────────────────────

/// 位數標籤（簡短版）。
String compareBasisLabelShort(CohortBenchmarkCompareBasis basis) =>
    switch (basis) {
      CohortBenchmarkCompareBasis.p10 => 'P10',
      CohortBenchmarkCompareBasis.p25 => 'P25',
      CohortBenchmarkCompareBasis.p50 => 'P50',
      CohortBenchmarkCompareBasis.p75 => 'P75',
      CohortBenchmarkCompareBasis.p90 => 'P90',
      CohortBenchmarkCompareBasis.mean => 'Mean',
    };

/// 位數標籤（完整版）。
String compareBasisLabelLong(CohortBenchmarkCompareBasis basis) =>
    switch (basis) {
      CohortBenchmarkCompareBasis.p10 => 'P10',
      CohortBenchmarkCompareBasis.p25 => 'P25',
      CohortBenchmarkCompareBasis.p50 => 'P50（中位數）',
      CohortBenchmarkCompareBasis.p75 => 'P75',
      CohortBenchmarkCompareBasis.p90 => 'P90',
      CohortBenchmarkCompareBasis.mean => 'Mean（平均）',
    };

/// 狀態標籤簡短版本。
String statusLabelShort(MetricComparisonStatus status) => switch (status) {
      MetricComparisonStatus.normal => '正常',
      MetricComparisonStatus.belowNormal => '偏低',
      MetricComparisonStatus.aboveNormal => '偏高',
    };

// ─────────────────────────────────────────────────────────────
// 指標方向判斷
// ─────────────────────────────────────────────────────────────

enum MetricBetterDirection { lowerIsBetter, higherIsBetter, unknown }

/// 判斷指標的「較佳」方向。
MetricBetterDirection betterDirectionForMetric({
  required String group,
  required String metricKey,
}) {
  // lap_time：時間越短通常越好
  if (group == 'lap_time') return MetricBetterDirection.lowerIsBetter;

  // speed_distance：速度越快通常越好
  if (group == 'speed_distance' && metricKey == 'speed_mps') {
    return MetricBetterDirection.higherIsBetter;
  }

  // 其他指標不同族群/情境下不一定能用「越大越好」簡化
  return MetricBetterDirection.unknown;
}

/// 取得「較佳/較差/正常」標籤。
String? betterWorseLabel({
  required String group,
  required String metricKey,
  required MetricComparisonStatus status,
}) {
  final dir = betterDirectionForMetric(group: group, metricKey: metricKey);
  if (dir == MetricBetterDirection.unknown) return null;

  if (status == MetricComparisonStatus.normal) return '正常';

  final isBetter = switch (dir) {
    MetricBetterDirection.lowerIsBetter =>
      status == MetricComparisonStatus.belowNormal,
    MetricBetterDirection.higherIsBetter =>
      status == MetricComparisonStatus.aboveNormal,
    MetricBetterDirection.unknown => false,
  };
  return isBetter ? '較佳' : '較差';
}


/// 佐百分比：以 `diff.p50_diff_pct` 表示「比族群中位數快/慢 X%」。
///
/// 注意：diff 的正負意義取決於指標方向：
/// - lowerIsBetter（例如時間）：diff>0 表示「更慢（較差）」；diff<0 表示「更快（較佳）」
/// - higherIsBetter（例如速度）：diff>0 表示「更快（較佳）」；diff<0 表示「更慢（較差）」
String? supportDiffLabelP50({
  required String group,
  required String metricKey,
  required MetricComparison c,
}) {
  final d = c.diff;
  if (d == null) return null;
  final diffPct = d.p50DiffPct;
  if (!diffPct.isFinite) return null;

  final dir = betterDirectionForMetric(group: group, metricKey: metricKey);
  final abs = diffPct.abs();

  if (abs < 0.0005) return '比中位數 持平';

  String verb;
  switch (dir) {
    case MetricBetterDirection.lowerIsBetter:
      verb = diffPct > 0 ? '慢' : '快';
      break;
    case MetricBetterDirection.higherIsBetter:
      verb = diffPct > 0 ? '快' : '慢';
      break;
    case MetricBetterDirection.unknown:
      return '比中位數 ${diffPct >= 0 ? '+' : '-'}${abs.toStringAsFixed(1)}%';
  }
  return '比中位數 $verb ${abs.toStringAsFixed(1)}%';
}

/// 取得差異標籤的顏色。
Color? supportDiffColorP50({
  required BuildContext context,
  required String group,
  required String metricKey,
  required MetricComparison c,
}) {
  final d = c.diff;
  if (d == null) return null;
  final diffPct = d.p50DiffPct;
  if (!diffPct.isFinite) return null;
  if (diffPct.abs() < 0.0005) return null;

  final dir = betterDirectionForMetric(group: group, metricKey: metricKey);
  if (dir == MetricBetterDirection.unknown) return null;

  final isBetter = switch (dir) {
    MetricBetterDirection.lowerIsBetter => diffPct < 0,
    MetricBetterDirection.higherIsBetter => diffPct > 0,
    MetricBetterDirection.unknown => false,
  };
  final colors = Theme.of(context).colorScheme;
  return isBetter ? colors.tertiary : colors.error;
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


/// 建立雷達圖資料項目。
List<BenchmarkRadarEntry> buildRadarEntries(
  BuildContext context,
  String title,
  Map<String, MetricComparison> map,
  List<String> order,
  Map<String, String> labelMap,
  CohortBenchmarkCompareBasis basis,
) {
  final palette = DashboardBenchmarkCompareColors.of(context);
  final rows = buildMetricItems(map, order: order, labelMap: labelMap);
  return rows
      .map((row) {
        final c = row.comparison;
        final userV = userValueForBasis(c, basis);
        final benchV = benchmarkValueForBasis(c, basis);
        final status = c.status;
        final color = switch (status) {
          MetricComparisonStatus.belowNormal => palette.lower,
          MetricComparisonStatus.aboveNormal => palette.higher,
          MetricComparisonStatus.normal => palette.inRange,
        };
        final diffPct = diffPctForBasis(c, basis);
        final diffText = diffPct == null
            ? ''
            : ' · 差異=${diffPct.toStringAsFixed(2)}%';
        return BenchmarkRadarEntry(
          key: '$title.${row.key}',
          label: row.label,
          percentile01: (percentilePositionForBasis(c, basis) / 100).clamp(
            0.0,
            1.0,
          ),
          valueText:
              '個人${compareBasisLabelShort(basis)}=${userV.toStringAsFixed(3)}（n=${c.userCount}） · 族群${compareBasisLabelShort(basis)}=${benchV.toStringAsFixed(3)}（n=${c.benchmarkCount}）$diffText · 族群P25=${c.benchmarkP25.toStringAsFixed(3)} · P50=${c.benchmarkP50.toStringAsFixed(3)} · P75=${c.benchmarkP75.toStringAsFixed(3)}',
          status: status,
          color: color,
        );
      })
      .toList(growable: false);
}
