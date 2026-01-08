import 'package:flutter/foundation.dart';

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}') ?? 0.0;
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? fallback;
}

DateTime? _tryParseDateTime(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

/// `GET /cohort-benchmark/list` 的單一族群資訊。
@immutable
class CohortBenchmarkListItem {
  const CohortBenchmarkListItem({
    required this.cohortName,
    required this.userCount,
    required this.sessionCount,
    required this.lapCount,
    required this.calculatedAt,
    required this.version,
  });

  final String cohortName;
  final int userCount;
  final int sessionCount;
  final int lapCount;
  final DateTime? calculatedAt;
  final int version;

  factory CohortBenchmarkListItem.fromJson(Map<String, dynamic> json) {
    return CohortBenchmarkListItem(
      cohortName: json['cohort_name']?.toString() ?? '',
      userCount: _toInt(json['user_count']),
      sessionCount: _toInt(json['session_count']),
      lapCount: _toInt(json['lap_count']),
      calculatedAt: _tryParseDateTime(json['calculated_at']),
      version: _toInt(json['version'], fallback: 1),
    );
  }
}

@immutable
class CohortBenchmarkListResponse {
  const CohortBenchmarkListResponse({
    required this.cohorts,
    required this.count,
  });

  final List<CohortBenchmarkListItem> cohorts;
  final int count;

  factory CohortBenchmarkListResponse.fromJson(Map<String, dynamic> json) {
    final cohortsJson = json['cohorts'];
    final cohorts = cohortsJson is List
        ? cohortsJson
            .whereType<Map<String, dynamic>>()
            .map(CohortBenchmarkListItem.fromJson)
            .toList(growable: false)
        : const <CohortBenchmarkListItem>[];
    return CohortBenchmarkListResponse(
      cohorts: cohorts,
      count: _toInt(json['count'], fallback: cohorts.length),
    );
  }
}

@immutable
class CohortUsersRequest {
  const CohortUsersRequest({
    required this.cohortNames,
    this.intersection = false,
  });

  final List<String> cohortNames;
  final bool intersection;

  Map<String, Object?> toJson() => <String, Object?>{
        'cohort_names': cohortNames,
        'intersection': intersection,
      };
}

@immutable
class CohortUsersResponse {
  const CohortUsersResponse({
    required this.cohortNames,
    required this.intersection,
    required this.userCodes,
    required this.count,
  });

  final List<String> cohortNames;
  final bool intersection;
  final List<String> userCodes;
  final int count;

  factory CohortUsersResponse.fromJson(Map<String, dynamic> json) {
    final cohortNames = (json['cohort_names'] is List)
        ? (json['cohort_names'] as List)
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final userCodes = (json['user_codes'] is List)
        ? (json['user_codes'] as List)
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final intersection = json['intersection'] is bool
        ? json['intersection'] as bool
        : ('${json['intersection']}'.toLowerCase().trim() == 'true');
    return CohortUsersResponse(
      cohortNames: cohortNames,
      intersection: intersection,
      userCodes: userCodes,
      count: _toInt(json['count'], fallback: userCodes.length),
    );
  }
}

/// 百分位數統計（族群分布）。
@immutable
class PercentileStats {
  const PercentileStats({
    required this.p10,
    required this.p25,
    required this.p50,
    required this.p75,
    required this.p90,
    required this.mean,
    required this.std,
    required this.count,
  });

  final double p10;
  final double p25;
  final double p50;
  final double p75;
  final double p90;
  final double mean;
  final double std;
  final int count;

  factory PercentileStats.fromJson(Map<String, dynamic> json) {
    return PercentileStats(
      p10: _toDouble(json['p10']),
      p25: _toDouble(json['p25']),
      p50: _toDouble(json['p50']),
      p75: _toDouble(json['p75']),
      p90: _toDouble(json['p90']),
      mean: _toDouble(json['mean']),
      std: _toDouble(json['std']),
      count: _toInt(json['count']),
    );
  }
}

Map<String, PercentileStats> _parsePercentileSection(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, PercentileStats>{};
  for (final entry in value.entries) {
    final key = entry.key?.toString() ?? '';
    if (key.isEmpty) continue;
    final v = entry.value;
    if (v is Map) {
      final casted = v.cast<String, dynamic>();
      if (casted.containsKey('p50')) {
        result[key] = PercentileStats.fromJson(casted);
      }
    }
  }
  return Map.unmodifiable(result);
}

Map<String, double> _parseRatioMap(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, double>{};
  for (final entry in value.entries) {
    final key = entry.key?.toString() ?? '';
    if (key.isEmpty) continue;
    result[key] = _toDouble(entry.value);
  }
  return Map.unmodifiable(result);
}

/// `GET /cohort-benchmark/{cohort_name}` 的基準值結果（同 calculate 回傳）。
@immutable
class CohortBenchmarkDetail {
  const CohortBenchmarkDetail({
    required this.cohortName,
    required this.calculatedAt,
    required this.version,
    required this.userCount,
    required this.sessionCount,
    required this.lapCount,
    required this.lapTime,
    required this.gait,
    required this.speedDistance,
    required this.turn,
    required this.turnConeDirRatio,
    required this.turnChairDirRatio,
  });

  final String cohortName;
  final DateTime? calculatedAt;
  final int version;
  final int userCount;
  final int sessionCount;
  final int lapCount;

  /// e.g. dur_total/dur_stand/...
  final Map<String, PercentileStats> lapTime;

  /// e.g. spm/mean_step_len/...
  final Map<String, PercentileStats> gait;

  /// e.g. speed_mps/dist_lap_path_m/...
  final Map<String, PercentileStats> speedDistance;

  /// e.g. delta_theta_cone_deg/delta_theta_chair_deg/...
  final Map<String, PercentileStats> turn;

  /// e.g. {"+1":0.6,"-1":0.4}
  final Map<String, double> turnConeDirRatio;
  final Map<String, double> turnChairDirRatio;

  PercentileStats? findStats(String group, String metricKey) {
    return switch (group) {
      'lap_time' => lapTime[metricKey],
      'gait' => gait[metricKey],
      'speed_distance' => speedDistance[metricKey],
      'turn' => turn[metricKey],
      _ => null,
    };
  }

  factory CohortBenchmarkDetail.fromJson(Map<String, dynamic> json) {
    final turnJson = json['turn'];
    final turnRatios = (turnJson is Map) ? turnJson.cast<String, dynamic>() : const <String, dynamic>{};
    return CohortBenchmarkDetail(
      cohortName: json['cohort_name']?.toString() ?? '',
      calculatedAt: _tryParseDateTime(json['calculated_at']),
      version: _toInt(json['version'], fallback: 1),
      userCount: _toInt(json['user_count']),
      sessionCount: _toInt(json['session_count']),
      lapCount: _toInt(json['lap_count']),
      lapTime: _parsePercentileSection(json['lap_time']),
      gait: _parsePercentileSection(json['gait']),
      speedDistance: _parsePercentileSection(json['speed_distance']),
      turn: _parsePercentileSection(turnJson),
      turnConeDirRatio: _parseRatioMap(turnRatios['turn_cone_dir_ratio']),
      turnChairDirRatio: _parseRatioMap(turnRatios['turn_chair_dir_ratio']),
    );
  }
}

enum MetricComparisonStatus { belowNormal, normal, aboveNormal }

MetricComparisonStatus _parseComparisonStatus(dynamic value) {
  final raw = value?.toString().trim().toLowerCase();
  return switch (raw) {
    'below_normal' => MetricComparisonStatus.belowNormal,
    'above_normal' => MetricComparisonStatus.aboveNormal,
    _ => MetricComparisonStatus.normal,
  };
}

@immutable
class PercentileDiff {
  const PercentileDiff({
    required this.p10DiffPct,
    required this.p25DiffPct,
    required this.p50DiffPct,
    required this.p75DiffPct,
    required this.p90DiffPct,
    required this.meanDiffPct,
    required this.p10PercentilePosition,
    required this.p25PercentilePosition,
    required this.p50PercentilePosition,
    required this.p75PercentilePosition,
    required this.p90PercentilePosition,
    required this.meanPercentilePosition,
  });

  /// 計算公式：(user - benchmark) / benchmark * 100
  final double p10DiffPct;
  final double p25DiffPct;
  final double p50DiffPct;
  final double p75DiffPct;
  final double p90DiffPct;
  final double meanDiffPct;

  /// 使用者該位數值在族群中的百分位位置（0-100）。
  final double? p10PercentilePosition;
  final double? p25PercentilePosition;
  final double? p50PercentilePosition;
  final double? p75PercentilePosition;
  final double? p90PercentilePosition;
  final double? meanPercentilePosition;

  factory PercentileDiff.fromJson(Map<String, dynamic> json) {
    return PercentileDiff(
      p10DiffPct: _toDouble(json['p10_diff_pct']),
      p25DiffPct: _toDouble(json['p25_diff_pct']),
      p50DiffPct: _toDouble(json['p50_diff_pct']),
      p75DiffPct: _toDouble(json['p75_diff_pct']),
      p90DiffPct: _toDouble(json['p90_diff_pct']),
      meanDiffPct: _toDouble(json['mean_diff_pct']),
      p10PercentilePosition: _toDoubleOrNull(json['p10_percentile_position']),
      p25PercentilePosition: _toDoubleOrNull(json['p25_percentile_position']),
      p50PercentilePosition: _toDoubleOrNull(json['p50_percentile_position']),
      p75PercentilePosition: _toDoubleOrNull(json['p75_percentile_position']),
      p90PercentilePosition: _toDoubleOrNull(json['p90_percentile_position']),
      meanPercentilePosition: _toDoubleOrNull(json['mean_percentile_position']),
    );
  }
}

@immutable
class MetricComparison {
  const MetricComparison({
    required this.userP10,
    required this.userP25,
    required this.userP50,
    required this.userP75,
    required this.userP90,
    required this.userMean,
    required this.userCount,
    required this.benchmarkP10,
    required this.percentilePosition,
    required this.benchmarkP25,
    required this.benchmarkP50,
    required this.benchmarkP75,
    required this.benchmarkP90,
    required this.benchmarkMean,
    required this.benchmarkCount,
    required this.inNormalRange,
    required this.status,
    required this.diff,
  });

  /// 個人統計（該 session 的所有圈）。
  final double userP10;
  final double userP25;
  final double userP50;
  final double userP75;
  final double userP90;
  final double userMean;
  final int userCount;

  /// 族群統計（預先計算的基準）。
  final double benchmarkP10;
  final double percentilePosition; // 0..100
  final double benchmarkP25;
  final double benchmarkP50;
  final double benchmarkP75;
  final double benchmarkP90;
  final double benchmarkMean;
  final int benchmarkCount;
  final bool inNormalRange;
  final MetricComparisonStatus status;
  final PercentileDiff? diff;

  factory MetricComparison.fromJson(Map<String, dynamic> json) {
    final inNormalRange = json['in_normal_range'] is bool
        ? json['in_normal_range'] as bool
        : ('${json['in_normal_range']}'.toLowerCase().trim() == 'true');
    final diffJson = json['diff'];
    return MetricComparison(
      userP10: _toDouble(json['user_p10']),
      userP25: _toDouble(json['user_p25']),
      userP50: _toDouble(json['user_p50']),
      userP75: _toDouble(json['user_p75']),
      userP90: _toDouble(json['user_p90']),
      userMean: _toDouble(json['user_mean']),
      userCount: _toInt(json['user_count']),
      benchmarkP10: _toDouble(json['benchmark_p10']),
      percentilePosition: _toDouble(json['percentile_position']),
      benchmarkP25: _toDouble(json['benchmark_p25']),
      benchmarkP50: _toDouble(json['benchmark_p50']),
      benchmarkP75: _toDouble(json['benchmark_p75']),
      benchmarkP90: _toDouble(json['benchmark_p90']),
      benchmarkMean: _toDouble(json['benchmark_mean']),
      benchmarkCount: _toInt(json['benchmark_count']),
      inNormalRange: inNormalRange,
      status: _parseComparisonStatus(json['status']),
      diff: diffJson is Map
          ? PercentileDiff.fromJson(diffJson.cast<String, dynamic>())
          : null,
    );
  }
}

Map<String, MetricComparison> _parseComparisonSection(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, MetricComparison>{};
  for (final entry in value.entries) {
    final key = entry.key?.toString() ?? '';
    if (key.isEmpty) continue;
    final v = entry.value;
    if (v is Map) {
      final casted = v.cast<String, dynamic>();
      if (casted.containsKey('percentile_position')) {
        result[key] = MetricComparison.fromJson(casted);
      }
    }
  }
  return Map.unmodifiable(result);
}

/// `POST /cohort-benchmark/compare` 回傳。
@immutable
class CohortBenchmarkCompareResponse {
  const CohortBenchmarkCompareResponse({
    required this.userCode,
    required this.sessionName,
    required this.cohortName,
    required this.comparedAt,
    required this.lapCount,
    required this.lapTime,
    required this.gait,
    required this.speedDistance,
    required this.turn,
  });

  final String userCode;
  final String sessionName;
  final String cohortName;
  final DateTime? comparedAt;
  final int lapCount;

  final Map<String, MetricComparison> lapTime;
  final Map<String, MetricComparison> gait;
  final Map<String, MetricComparison> speedDistance;
  final Map<String, MetricComparison> turn;

  MetricComparison? findComparison(String group, String metricKey) {
    return switch (group) {
      'lap_time' => lapTime[metricKey],
      'gait' => gait[metricKey],
      'speed_distance' => speedDistance[metricKey],
      'turn' => turn[metricKey],
      _ => null,
    };
  }

  factory CohortBenchmarkCompareResponse.fromJson(Map<String, dynamic> json) {
    return CohortBenchmarkCompareResponse(
      userCode: json['user_code']?.toString() ?? '',
      sessionName: json['session_name']?.toString() ?? '',
      cohortName: json['cohort_name']?.toString() ?? '',
      comparedAt: _tryParseDateTime(json['compared_at']),
      lapCount: _toInt(json['lap_count']),
      lapTime: _parseComparisonSection(json['lap_time']),
      gait: _parseComparisonSection(json['gait']),
      speedDistance: _parseComparisonSection(json['speed_distance']),
      turn: _parseComparisonSection(json['turn']),
    );
  }
}

// =============================================================================
// Delete APIs
// =============================================================================

@immutable
class CohortBenchmarkDeleteBatchResponse {
  const CohortBenchmarkDeleteBatchResponse({
    required this.ok,
    required this.deleted,
    required this.deletedCount,
    required this.notFound,
  });

  final bool ok;
  final List<String> deleted;
  final int deletedCount;
  final List<String>? notFound;

  factory CohortBenchmarkDeleteBatchResponse.fromJson(Map<String, dynamic> json) {
    final ok = json['ok'] is bool
        ? json['ok'] as bool
        : ('${json['ok']}'.toLowerCase().trim() == 'true');
    final deleted = (json['deleted'] is List)
        ? (json['deleted'] as List)
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final notFound = (json['not_found'] is List)
        ? (json['not_found'] as List)
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
        : null;
    return CohortBenchmarkDeleteBatchResponse(
      ok: ok,
      deleted: deleted,
      deletedCount: _toInt(json['deleted_count'], fallback: deleted.length),
      notFound: notFound == null || notFound.isEmpty ? null : notFound,
    );
  }
}


