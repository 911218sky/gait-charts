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

/// 指標比對狀態：worse=較差, similar=相近, better=較好。
enum MetricComparisonStatus { worse, similar, better }

MetricComparisonStatus _parseComparisonStatus(dynamic value) {
  final raw = value?.toString().trim().toLowerCase();
  return switch (raw) {
    'worse' => MetricComparisonStatus.worse,
    'better' => MetricComparisonStatus.better,
    _ => MetricComparisonStatus.similar,
  };
}

/// 單一指標比對結果（簡化版）。
///
/// 前端只需關注：
/// - [diffPct]: 正數表示比族群高，負數表示比族群低
/// - [isBetter]: 這個差異對使用者是好是壞
/// - [status]: worse/similar/better
@immutable
class MetricComparison {
  const MetricComparison({
    required this.userValue,
    required this.cohortValue,
    required this.diffPct,
    required this.isBetter,
    required this.status,
  });

  /// 使用者數值。
  final double userValue;

  /// 族群基準值。
  final double cohortValue;

  /// 差異百分比：正數=比族群高，負數=比族群低。
  final double diffPct;

  /// 這個差異對使用者是否有利（考慮指標方向）。
  final bool isBetter;

  /// 狀態：worse=較差, similar=相近, better=較好。
  final MetricComparisonStatus status;

  factory MetricComparison.fromJson(Map<String, dynamic> json) {
    final isBetter = json['is_better'] is bool
        ? json['is_better'] as bool
        : ('${json['is_better']}'.toLowerCase().trim() == 'true');
    return MetricComparison(
      userValue: _toDouble(json['user_value']),
      cohortValue: _toDouble(json['cohort_value']),
      diffPct: _toDouble(json['diff_pct']),
      isBetter: isBetter,
      status: _parseComparisonStatus(json['status']),
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
      // 新 API 使用 status 欄位
      if (casted.containsKey('status')) {
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
    required this.functional,
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

  /// 功能評估（基於論文標準值）。
  final FunctionalAssessment? functional;

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
    final functionalJson = json['functional'];
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
      functional: functionalJson is Map
          ? FunctionalAssessment.fromJson(functionalJson.cast<String, dynamic>())
          : null,
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

// =============================================================================
// Functional Assessment Models
// =============================================================================

/// 功能性評估單一指標。
@immutable
class FunctionalMetric {
  const FunctionalMetric({
    required this.userValue,
    required this.referenceValue,
    required this.diffFromReferencePct,
    required this.higherIsBetter,
    required this.radarScore,
    this.cohortValue,
  });

  /// 使用者數值（秒）。
  final double userValue;

  /// 參考值（健康成人研究數據，來自論文標準值）。
  final double referenceValue;

  /// 與參考值的差異百分比。
  final double diffFromReferencePct;

  /// 該指標是否越高越好。
  final bool higherIsBetter;

  /// 族群數值（可選）。
  final double? cohortValue;

  /// 雷達圖分數（0-100，50 = 參考值）。
  final double radarScore;

  factory FunctionalMetric.fromJson(Map<String, dynamic> json) {
    final higherIsBetter = json['higher_is_better'] is bool
        ? json['higher_is_better'] as bool
        : ('${json['higher_is_better']}'.toLowerCase().trim() == 'true');
    return FunctionalMetric(
      userValue: _toDouble(json['user_value']),
      referenceValue: _toDouble(json['reference_value']),
      diffFromReferencePct: _toDouble(json['diff_from_reference_pct']),
      higherIsBetter: higherIsBetter,
      cohortValue: _toDoubleOrNull(json['cohort_value']),
      radarScore: _toDouble(json['radar_score']),
    );
  }
}

Map<String, FunctionalMetric> _parseFunctionalMetricMap(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, FunctionalMetric>{};
  for (final entry in value.entries) {
    final key = entry.key?.toString() ?? '';
    if (key.isEmpty) continue;
    final v = entry.value;
    if (v is Map) {
      result[key] = FunctionalMetric.fromJson(v.cast<String, dynamic>());
    }
  }
  return Map.unmodifiable(result);
}

/// 功能性評估資料（體能、平衡、肌耐力）。
@immutable
class FunctionalAssessment {
  const FunctionalAssessment({
    required this.endurance,
    required this.balance,
    required this.muscleEndurance,
  });

  /// 體能指標（基於 6 分鐘步行測試）。
  final Map<String, FunctionalMetric> endurance;

  /// 平衡能力指標（基於 TUG 測試）。
  final Map<String, FunctionalMetric> balance;

  /// 肌耐力指標（基於 TUG 測試）。
  final Map<String, FunctionalMetric> muscleEndurance;

  bool get hasData =>
      endurance.isNotEmpty ||
      balance.isNotEmpty ||
      muscleEndurance.isNotEmpty;

  static const empty = FunctionalAssessment(
    endurance: {},
    balance: {},
    muscleEndurance: {},
  );

  factory FunctionalAssessment.fromJson(Map<String, dynamic> json) {
    return FunctionalAssessment(
      endurance: _parseFunctionalMetricMap(json['endurance']),
      balance: _parseFunctionalMetricMap(json['balance']),
      muscleEndurance: _parseFunctionalMetricMap(json['muscle_endurance']),
    );
  }
}


