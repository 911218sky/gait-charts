part of 'dashboard_overview.dart';

/// 步態週期相位 API 回應。
///
/// 包含左右腳的步態週期相位資料，用於繪製步態時間軸圖。
class GaitCyclePhasesResponse {
  const GaitCyclePhasesResponse({
    this.left,
    this.right,
    this.rightOffsetPct,
  });

  /// 左腳步態相位資料，無有效數據時為 null。
  final GaitPhaseData? left;

  /// 右腳步態相位資料，無有效數據時為 null。
  final GaitPhaseData? right;

  /// 右腳繪製時的水平偏移量 (%)，用於對齊雙支撐期。
  final double? rightOffsetPct;

  /// 是否有有效資料。
  bool get isEmpty => left == null && right == null;

  bool get hasLeft => left != null;
  bool get hasRight => right != null;

  static const empty = GaitCyclePhasesResponse();

  factory GaitCyclePhasesResponse.fromJson(Map<String, dynamic> json) {
    return GaitCyclePhasesResponse(
      left: json['left'] != null
          ? GaitPhaseData.fromJson(json['left'] as Map<String, dynamic>)
          : null,
      right: json['right'] != null
          ? GaitPhaseData.fromJson(json['right'] as Map<String, dynamic>)
          : null,
      rightOffsetPct: _toNullableDouble(json['right_offset_pct']),
    );
  }
}

/// 單側步態相位資料。
class GaitPhaseData {
  const GaitPhaseData({
    required this.side,
    required this.ds1Pct,
    required this.singleSupportPct,
    required this.ds2Pct,
    required this.swingPct,
    required this.stancePct,
    required this.avgCycleTimeS,
    required this.nCycles,
  });

  /// 側別：`"L"` 或 `"R"`。
  final String side;

  /// 初始雙支撐期百分比 (%)。
  final double ds1Pct;

  /// 單支撐期百分比 (%)。
  final double singleSupportPct;

  /// 終末雙支撐期百分比 (%)。
  final double ds2Pct;

  /// 擺動期百分比 (%)。
  final double swingPct;

  /// 總支撐期百分比 (%) = ds1 + ss + ds2。
  final double stancePct;

  /// 平均步態週期時間 (秒)。
  final double avgCycleTimeS;

  /// 用於計算平均的有效週期數。
  final int nCycles;

  bool get isLeft => side == 'L';
  bool get isRight => side == 'R';

  factory GaitPhaseData.fromJson(Map<String, dynamic> json) {
    return GaitPhaseData(
      side: _stringValue(json['side']),
      ds1Pct: _toDouble(json['ds1_pct']),
      singleSupportPct: _toDouble(json['single_support_pct']),
      ds2Pct: _toDouble(json['ds2_pct']),
      swingPct: _toDouble(json['swing_pct']),
      stancePct: _toDouble(json['stance_pct']),
      avgCycleTimeS: _toDouble(json['avg_cycle_time_s']),
      nCycles: _toInt(json['n_cycles']),
    );
  }
}

/// 步態週期相位 API 的查詢設定。
class GaitCyclePhasesConfig {
  const GaitCyclePhasesConfig({
    this.projection = 'xz',
    this.smoothWindowS = 0.1,
    this.flatFrac = 0.15,
    this.minVAbs = 0.05,
  });

  final String projection;
  final double smoothWindowS;
  final double flatFrac;
  final double minVAbs;

  Map<String, dynamic> toJson() => {
        'projection': projection,
        'smooth_window_s': smoothWindowS,
        'flat_frac': flatFrac,
        'min_v_abs': minVAbs,
      };

  GaitCyclePhasesConfig copyWith({
    String? projection,
    double? smoothWindowS,
    double? flatFrac,
    double? minVAbs,
  }) {
    return GaitCyclePhasesConfig(
      projection: projection ?? this.projection,
      smoothWindowS: smoothWindowS ?? this.smoothWindowS,
      flatFrac: flatFrac ?? this.flatFrac,
      minVAbs: minVAbs ?? this.minVAbs,
    );
  }
}
