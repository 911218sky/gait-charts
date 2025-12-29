part of 'dashboard_overview.dart';

/// 步態分期持續時間回應資料模型。
class StageDurationsResponse {
  const StageDurationsResponse({required this.laps});

  final List<LapSummary> laps; // 所有圈數的摘要

  bool get isEmpty => laps.isEmpty;

  factory StageDurationsResponse.fromJson(Map<String, dynamic> json) {
    final lapsJson = json['laps'];
    if (lapsJson is List) {
      return StageDurationsResponse(
        laps: lapsJson
            .whereType<Map<String, dynamic>>()
            .map(LapSummary.fromJson)
            .toList(),
      );
    }
    return const StageDurationsResponse(laps: []);
  }

  static const empty = StageDurationsResponse(laps: []);
}

/// 儲存單圈的摘要資訊與各階段計算結果。
class LapSummary {
  LapSummary({
    required this.lapIndex,
    required this.startTimestampSeconds,
    required this.endTimestampSeconds,
    required this.totalDurationSeconds,
    required this.totalDistanceMeters,
    required this.stages,
  });

  final int lapIndex; // 圈數索引
  final double startTimestampSeconds; // 開始時間 (秒)
  final double endTimestampSeconds; // 結束時間 (秒)
  final double totalDurationSeconds; // 總持續時間 (秒)
  final double totalDistanceMeters; // 總距離 (公尺)
  final List<StageDurationStage> stages; // 該圈內的各階段資料

  factory LapSummary.fromJson(Map<String, dynamic> json) {
    final stagesJson = json['stage_durations'];
    return LapSummary(
      lapIndex: _toInt(json['lap_index']),
      startTimestampSeconds: _toDouble(json['ts_start']),
      endTimestampSeconds: _toDouble(json['ts_end']),
      totalDurationSeconds: _toDouble(json['total_duration_s']),
      totalDistanceMeters: _toDouble(json['total_distance_m']),
      stages: stagesJson is List
          ? stagesJson
                .whereType<Map<String, dynamic>>()
                .map(StageDurationStage.fromJson)
                .toList()
          : const [],
    );
  }
}

/// 代表單一階段的持續時間與距離。
class StageDurationStage {
  const StageDurationStage({
    required this.label,
    required this.durationSeconds,
    this.distanceMeters,
  });

  final String label; // 階段標籤
  final double durationSeconds; // 持續時間 (秒)
  final double? distanceMeters; // 距離 (公尺)

  factory StageDurationStage.fromJson(Map<String, dynamic> json) {
    return StageDurationStage(
      label: _stringValue(json['label']),
      durationSeconds: _toDouble(json['duration_s']),
      distanceMeters: json.containsKey('distance_m')
          ? _toDouble(json['distance_m'])
          : null,
    );
  }
}

/// 允許使用者調整投影平面與檢測參數的查詢設定。
class StageDurationsConfig {
  const StageDurationsConfig({
    this.projection = 'xz',
    this.smoothWindow = 3,
    this.minVAbs = 15,
    this.flatFrac = 0.7,
  });

  final String projection; // 投影平面 (例如: xz)
  final int smoothWindow; // 平滑化視窗大小
  final double minVAbs; // 偵測步態的最小速度閾值
  final double flatFrac; // 平坦區段判定比例

  StageDurationsConfig copyWith({
    String? projection,
    int? smoothWindow,
    double? minVAbs,
    double? flatFrac,
  }) {
    return StageDurationsConfig(
      projection: projection ?? this.projection,
      smoothWindow: smoothWindow ?? this.smoothWindow,
      minVAbs: minVAbs ?? this.minVAbs,
      flatFrac: flatFrac ?? this.flatFrac,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'projection': projection,
    'smooth_window_s': smoothWindow,
    'min_v_abs': minVAbs,
    'flat_frac': flatFrac,
  };
}

/// 匯總統計資料，提供儀表板摘要卡使用。
class StageDurationsAnalytics {
  StageDurationsAnalytics({
    required this.totalLaps,
    required this.averageLapDuration,
    required this.fastestLapDuration,
    required this.totalDistanceMeters,
    required this.stageAverageDurations,
  });

  final int totalLaps; // 總圈數
  final double averageLapDuration; // 平均單圈時間
  final double fastestLapDuration; // 最快單圈時間
  final double totalDistanceMeters; // 總距離
  final Map<String, double> stageAverageDurations; // 各階段平均時間
}

/// 從原始回應計算 Dashboard 所需的統計摘要。
StageDurationsAnalytics computeAnalytics(StageDurationsResponse response) {
  final laps = response.laps;
  if (laps.isEmpty) {
    return StageDurationsAnalytics(
      totalLaps: 0,
      averageLapDuration: 0,
      fastestLapDuration: 0,
      totalDistanceMeters: 0,
      stageAverageDurations: const {},
    );
  }

  final totalDuration = laps.fold<double>(
    0,
    (sum, lap) => sum + lap.totalDurationSeconds,
  );
  final fastestLap = laps
      .map((lap) => lap.totalDurationSeconds)
      .reduce((value, element) => value < element ? value : element);
  final totalDistance = laps.fold<double>(
    0,
    (sum, lap) => sum + lap.totalDistanceMeters,
  );

  final stageDurations = <String, List<double>>{};
  for (final lap in laps) {
    for (final stage in lap.stages) {
      stageDurations
          .putIfAbsent(stage.label, () => [])
          .add(stage.durationSeconds);
    }
  }

  final stageAverageDurations = <String, double>{
    for (final entry in stageDurations.entries)
      entry.key:
          entry.value.reduce((value, element) => value + element) /
          entry.value.length,
  };

  return StageDurationsAnalytics(
    totalLaps: laps.length,
    averageLapDuration: totalDuration / laps.length,
    fastestLapDuration: fastestLap,
    totalDistanceMeters: totalDistance,
    stageAverageDurations: stageAverageDurations,
  );
}
