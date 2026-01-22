import 'package:flutter/foundation.dart';

/// 圖表最大點數設定，用於控制渲染效能。
@immutable
class ChartConfig {
  const ChartConfig({
    this.yHeightDiffMaxPoints = 250,
    this.perLapSeriesMaxPoints = 250,
    this.perLapThetaMaxPoints = 250,
    this.perLapOverviewMaxPoints = 500,
    this.spatialSpectrumMaxPoints = 250,
    this.multiFftMaxPoints = 250,
  });

  /// 高度差圖表最大顯示點數，超過時執行降採樣。
  final int yHeightDiffMaxPoints;

  /// 每圈序列圖表最大顯示點數。
  final int perLapSeriesMaxPoints;

  /// 每圈角度變化圖表最大顯示點數。
  final int perLapThetaMaxPoints;

  /// 全景圖表最大顯示點數，預設較高以涵蓋較長時間範圍。
  final int perLapOverviewMaxPoints;

  /// 空間頻譜圖表最大顯示點數。
  final int spatialSpectrumMaxPoints;

  /// 多關節頻譜圖表最大顯示點數。
  final int multiFftMaxPoints;

  ChartConfig copyWith({
    int? yHeightDiffMaxPoints,
    int? perLapSeriesMaxPoints,
    int? perLapThetaMaxPoints,
    int? perLapOverviewMaxPoints,
    int? spatialSpectrumMaxPoints,
    int? multiFftMaxPoints,
  }) {
    return ChartConfig(
      yHeightDiffMaxPoints: yHeightDiffMaxPoints ?? this.yHeightDiffMaxPoints,
      perLapSeriesMaxPoints:
          perLapSeriesMaxPoints ?? this.perLapSeriesMaxPoints,
      perLapThetaMaxPoints: perLapThetaMaxPoints ?? this.perLapThetaMaxPoints,
      perLapOverviewMaxPoints:
          perLapOverviewMaxPoints ?? this.perLapOverviewMaxPoints,
      spatialSpectrumMaxPoints:
          spatialSpectrumMaxPoints ?? this.spatialSpectrumMaxPoints,
      multiFftMaxPoints: multiFftMaxPoints ?? this.multiFftMaxPoints,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'y_height_diff_max_points': yHeightDiffMaxPoints,
    'per_lap_series_max_points': perLapSeriesMaxPoints,
    'per_lap_theta_max_points': perLapThetaMaxPoints,
    'per_lap_overview_max_points': perLapOverviewMaxPoints,
    'spatial_spectrum_max_points': spatialSpectrumMaxPoints,
    'multi_fft_max_points': multiFftMaxPoints,
  };

  factory ChartConfig.fromJson(Map<String, dynamic> json) {
    return ChartConfig(
      yHeightDiffMaxPoints: _toPositiveInt(
        json['y_height_diff_max_points'],
        fallback: 250,
      ),
      perLapSeriesMaxPoints: _toPositiveInt(
        json['per_lap_series_max_points'],
        fallback: 250,
      ),
      perLapThetaMaxPoints: _toPositiveInt(
        json['per_lap_theta_max_points'],
        fallback: 250,
      ),
      perLapOverviewMaxPoints: _toPositiveInt(
        json['per_lap_overview_max_points'],
        fallback: 500,
      ),
      spatialSpectrumMaxPoints: _toPositiveInt(
        json['spatial_spectrum_max_points'],
        fallback: 360,
      ),
      multiFftMaxPoints: _toPositiveInt(
        json['multi_fft_max_points'],
        fallback: 450,
      ),
    );
  }

  @override
  String toString() {
    return 'ChartConfig('
        'yHeightDiffMaxPoints: $yHeightDiffMaxPoints, '
        'perLapSeriesMaxPoints: $perLapSeriesMaxPoints, '
        'perLapThetaMaxPoints: $perLapThetaMaxPoints, '
        'perLapOverviewMaxPoints: $perLapOverviewMaxPoints, '
        'spatialSpectrumMaxPoints: $spatialSpectrumMaxPoints, '
        'multiFftMaxPoints: $multiFftMaxPoints'
        ')';
  }
}

const defaultChartConfig = ChartConfig();

int _toPositiveInt(dynamic value, {required int fallback}) {
  if (value is num && value.isFinite && value > 0) {
    return value.toInt();
  }
  return fallback;
}
