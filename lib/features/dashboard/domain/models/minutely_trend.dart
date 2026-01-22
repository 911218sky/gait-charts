part of 'dashboard_overview.dart';

/// 每分鐘趨勢資料回應。
class MinutelyTrendResponse {
  const MinutelyTrendResponse({
    required this.minutes,
    required this.avgSpeeds,
    required this.lapCounts,
    required this.lapDetails,
  });

  /// 分鐘序號（1-based）。
  final List<int> minutes;

  /// 各分鐘平均速度 (m/s)，null 表示該分鐘無有效數據。
  final List<double?> avgSpeeds;

  /// 各分鐘完成圈數。
  final List<int> lapCounts;

  /// 各分鐘包含的圈數索引（1-based）。
  final List<List<int>> lapDetails;

  bool get isEmpty => minutes.isEmpty;

  static const empty = MinutelyTrendResponse(
    minutes: [],
    avgSpeeds: [],
    lapCounts: [],
    lapDetails: [],
  );

  factory MinutelyTrendResponse.fromJson(Map<String, dynamic> json) {
    final minutesJson = json['minutes'];
    final avgSpeedsJson = json['avg_speeds'];
    final lapCountsJson = json['lap_counts'];
    final lapDetailsJson = json['lap_details'];

    return MinutelyTrendResponse(
      minutes: minutesJson is List
          ? minutesJson.map(_toInt).toList()
          : const [],
      avgSpeeds: avgSpeedsJson is List
          ? avgSpeedsJson.map<double?>((v) => v == null ? null : _toDouble(v)).toList()
          : const [],
      lapCounts: lapCountsJson is List
          ? lapCountsJson.map(_toInt).toList()
          : const [],
      lapDetails: lapDetailsJson is List
          ? lapDetailsJson.map<List<int>>((item) {
              if (item is List) {
                return item.map(_toInt).toList();
              }
              return const [];
            }).toList()
          : const [],
    );
  }
}

/// minutely_trend API 的查詢設定。
class MinutelyTrendConfig {
  const MinutelyTrendConfig({
    this.projection = 'xz',
    this.smoothWindowSeconds = 0.2,
    this.minVAbs = 0.15,
    this.flatFrac = 0.3,
    this.maxMinutes,
  });

  final String projection;
  final double smoothWindowSeconds;
  final double minVAbs;
  final double flatFrac;
  final int? maxMinutes; // 限制輸出前 N 分鐘

  MinutelyTrendConfig copyWith({
    String? projection,
    double? smoothWindowSeconds,
    double? minVAbs,
    double? flatFrac,
    int? maxMinutes,
  }) {
    return MinutelyTrendConfig(
      projection: projection ?? this.projection,
      smoothWindowSeconds: smoothWindowSeconds ?? this.smoothWindowSeconds,
      minVAbs: minVAbs ?? this.minVAbs,
      flatFrac: flatFrac ?? this.flatFrac,
      maxMinutes: maxMinutes ?? this.maxMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'projection': projection,
      'smooth_window_s': smoothWindowSeconds,
      'min_v_abs': minVAbs,
      'flat_frac': flatFrac,
    };
    if (maxMinutes != null) {
      map['max_minutes'] = maxMinutes;
    }
    return map;
  }
}
