import 'package:flutter/foundation.dart';

/// 控制各圖表的最大點數設定，集中管理渲染效能。
@immutable
class ChartConfig {
  const ChartConfig({
    this.yHeightDiffMaxPoints = 250,
    this.perLapSeriesMaxPoints = 250,
    this.perLapPsdMaxPoints = 250,
    this.perLapThetaMaxPoints = 250,
    this.perLapOverviewMaxPoints = 500,
    this.spatialSpectrumMaxPoints = 250,
    this.multiFftMaxPoints = 250,
  });

  /// [Y-Height Diff] 高度差圖表的最大顯示點數。
  /// 超過此點數時，圖表元件應執行降採樣以維持效能。
  final int yHeightDiffMaxPoints;

  /// [Per-lap Series] 每圈序列 (Raw Data) 圖表的最大顯示點數。
  final int perLapSeriesMaxPoints;

  /// [Per-lap PSD] 每圈功率譜密度 (PSD) 圖表的最大顯示點數。
  final int perLapPsdMaxPoints;

  /// [Per-lap θ(t)] 每圈角度變化圖表的最大顯示點數。
  final int perLapThetaMaxPoints;

  /// [Panorama] 全景 (Overview) 圖表的最大顯示點數。
  /// 通常全景圖需要顯示較長範圍的數據，因此預設值較高。
  final int perLapOverviewMaxPoints;

  /// [Spatial Spectrum] 空間頻譜圖表的最大顯示點數。
  final int spatialSpectrumMaxPoints;

  /// [Multi-FFT] 多關節頻譜圖表的最大顯示點數。
  final int multiFftMaxPoints;

  ChartConfig copyWith({
    int? yHeightDiffMaxPoints,
    int? perLapSeriesMaxPoints,
    int? perLapPsdMaxPoints,
    int? perLapThetaMaxPoints,
    int? perLapOverviewMaxPoints,
    int? spatialSpectrumMaxPoints,
    int? multiFftMaxPoints,
  }) {
    return ChartConfig(
      yHeightDiffMaxPoints: yHeightDiffMaxPoints ?? this.yHeightDiffMaxPoints,
      perLapSeriesMaxPoints:
          perLapSeriesMaxPoints ?? this.perLapSeriesMaxPoints,
      perLapPsdMaxPoints: perLapPsdMaxPoints ?? this.perLapPsdMaxPoints,
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
    'per_lap_psd_max_points': perLapPsdMaxPoints,
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
      perLapPsdMaxPoints: _toPositiveInt(
        json['per_lap_psd_max_points'],
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
        'perLapPsdMaxPoints: $perLapPsdMaxPoints, '
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
