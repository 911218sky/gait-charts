part of 'dashboard_overview.dart';

/// 左右關節 Y 軸高度差回應。
class YHeightDiffResponse {
  const YHeightDiffResponse({
    required this.timeSeconds,
    required this.left,
    required this.right,
    required this.diff,
    required this.leftJoint,
    required this.rightJoint,
  });

  final List<double> timeSeconds;
  final List<double> left;
  final List<double> right;
  final List<double> diff;
  final int leftJoint;
  final int rightJoint;

  bool get isEmpty =>
      timeSeconds.isEmpty || left.isEmpty || right.isEmpty || diff.isEmpty;

  static const empty = YHeightDiffResponse(
    timeSeconds: [],
    left: [],
    right: [],
    diff: [],
    leftJoint: 0,
    rightJoint: 0,
  );

  factory YHeightDiffResponse.fromJson(Map<String, dynamic> json) {
    return YHeightDiffResponse(
      timeSeconds: _toF32ZlibB64DecodedList(
        json['time_s_f32_zlib_b64']
      ),
      left: _toF32ZlibB64DecodedList(json['left_f32_zlib_b64']),
      right: _toF32ZlibB64DecodedList(json['right_f32_zlib_b64']),
      diff: _toF32ZlibB64DecodedList(json['diff_f32_zlib_b64']),
      leftJoint: _toInt(json['left_joint']),
      rightJoint: _toInt(json['right_joint']),
    );
  }
}

/// y_height_diff API 的查詢設定。
class YHeightDiffConfig {
  const YHeightDiffConfig({
    // 預設平滑視窗：3
    // 目標是在不過度鈍化曲線的前提下，減少感測雜訊造成的抖動。
    this.smoothWindow = 3,
    // Height Symmetry Monitor 預設以腳跟(heel)做對稱性比對：
    // 腳跟在步態中通常較穩定、也較符合臨床觀察的接觸事件。
    this.leftJoint = 29,
    this.rightJoint = 30,
    this.shiftToZero = true,
  });

  final int smoothWindow;
  final int leftJoint;
  final int rightJoint;
  final bool shiftToZero;

  YHeightDiffConfig copyWith({
    int? smoothWindow,
    int? leftJoint,
    int? rightJoint,
    bool? shiftToZero,
  }) {
    return YHeightDiffConfig(
      smoothWindow: smoothWindow ?? this.smoothWindow,
      leftJoint: leftJoint ?? this.leftJoint,
      rightJoint: rightJoint ?? this.rightJoint,
      shiftToZero: shiftToZero ?? this.shiftToZero,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'smooth_window_s': smoothWindow,
    'left_joint': leftJoint,
    'right_joint': rightJoint,
    'shift_to_zero': shiftToZero,
  };
}
