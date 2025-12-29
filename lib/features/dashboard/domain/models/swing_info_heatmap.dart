part of 'dashboard_overview.dart';

/// /swing_info_heatmap API 的回應資料。
///
/// 設計意圖：
/// - 後端回傳「每分鐘區間」的左右擺動期統計（百分比與秒數）。
/// - 前端以 2 x minutes 的矩陣自行渲染熱力圖。
class SwingInfoHeatmapResponse {
  const SwingInfoHeatmapResponse({
    required this.minutes,
    required this.swingPct,
    required this.swingSeconds,
  });

  /// 分鐘序列（1-based），長度 = minutesCount。
  final List<int> minutes;

  /// 擺動期百分比矩陣：row=0(left), row=1(right), col=minute-1。
  final List<List<double?>> swingPct;

  /// 擺動期秒數矩陣：row=0(left), row=1(right), col=minute-1。
  final List<List<double?>> swingSeconds;

  bool get isEmpty => minutes.isEmpty;

  int get minutesCount => minutes.length;

  /// swingPct 的最小值（忽略 null/NaN/Inf）。
  double? get pctMin => _foldFinite(
    swingPct,
    (current, next) => current == null ? next : (current < next ? current : next),
  );

  /// swingPct 的最大值（忽略 null/NaN/Inf）。
  double? get pctMax => _foldFinite(
    swingPct,
    (current, next) => current == null ? next : (current > next ? current : next),
  );

  /// swingSeconds 的最小值（忽略 null/NaN/Inf）。
  double? get secMin => _foldFinite(
    swingSeconds,
    (current, next) => current == null ? next : (current < next ? current : next),
  );

  /// swingSeconds 的最大值（忽略 null/NaN/Inf）。
  double? get secMax => _foldFinite(
    swingSeconds,
    (current, next) => current == null ? next : (current > next ? current : next),
  );

  static const empty = SwingInfoHeatmapResponse(
    minutes: <int>[],
    swingPct: <List<double?>>[],
    swingSeconds: <List<double?>>[],
  );

  factory SwingInfoHeatmapResponse.fromJson(Map<String, dynamic> json) {
    final minutes = _parseMinutes(json['minutes']);
    return SwingInfoHeatmapResponse(
      minutes: minutes,
      swingPct: _parseMatrix2xN(json['swing_pct'], expectedCols: minutes.length),
      swingSeconds: _parseMatrix2xN(
        json['swing_s'],
        expectedCols: minutes.length,
      ),
    );
  }

  static List<int> _parseMinutes(dynamic value) {
    if (value is! List) return const <int>[];
    final out = <int>[];
    for (final item in value) {
      final n = _toInt(item);
      if (n > 0) out.add(n);
    }
    return out;
  }

  static List<List<double?>> _parseMatrix2xN(
    dynamic value, {
    required int expectedCols,
  }) {
    // 容忍後端回傳 numpy array 轉成 list 的各種形狀：
    // - List<List<num?>> (理想)
    // - List<num?> (單列)
    // - 其他型別 -> 回傳空
    if (value is! List) return const <List<double?>>[];

    final rows = <List<double?>>[];
    for (final row in value) {
      if (row is List) {
        rows.add(row.map<double?>(_toNullableDouble).toList());
      } else if (row is num || row is String || row == null) {
        // 允許 value 直接是一維資料（極端情況）
        rows.add(<double?>[_toNullableDouble(row)]);
      }
    }

    // 確保至少 2 row，且每列長度對齊 expectedCols（不足補 null，過長截斷）。
    while (rows.length < 2) {
      rows.add(const <double?>[]);
    }
    final normalized = rows.take(2).map((r) {
      if (expectedCols <= 0) return <double?>[...r];
      if (r.length == expectedCols) return <double?>[...r];
      if (r.length > expectedCols) return r.sublist(0, expectedCols);
      return <double?>[...r, ...List<double?>.filled(expectedCols - r.length, null)];
    }).toList(growable: false);

    return normalized;
  }

  static double? _foldFinite(
    List<List<double?>> matrix,
    double? Function(double? current, double next) combiner,
  ) {
    double? acc;
    for (final row in matrix) {
      for (final value in row) {
        if (value == null || value.isNaN || value.isInfinite) continue;
        acc = combiner(acc, value);
      }
    }
    return acc;
  }
}

/// /swing_info_heatmap API 的查詢設定。
///
/// 對應後端 SwingInfoHeatmapRequest：
/// - smooth_window_s
/// - projection
/// - flat_frac
/// - min_v_abs
/// - max_minutes（可選）
class SwingInfoHeatmapConfig {
  const SwingInfoHeatmapConfig({
    this.smoothWindowS = 3,
    this.projection = 'xz',
    this.flatFrac = 0.7,
    this.minVAbs = 15,
    this.maxMinutes,
    this.vminPct = 30.0,
    this.vmaxPct = 45.0,
  });

  final double smoothWindowS;
  final String projection;
  final double flatFrac;
  final double minVAbs;
  final int? maxMinutes;

  /// 視覺化設定：顏色下限 (pct)，不傳給 API。
  final double? vminPct;

  /// 視覺化設定：顏色上限 (pct)，不傳給 API。
  final double? vmaxPct;

  SwingInfoHeatmapConfig copyWith({
    double? smoothWindowS,
    String? projection,
    double? flatFrac,
    double? minVAbs,
    int? maxMinutes,
    bool clearMaxMinutes = false,
    double? vminPct,
    double? vmaxPct,
    bool clearColorRange = false,
  }) {
    return SwingInfoHeatmapConfig(
      smoothWindowS: smoothWindowS ?? this.smoothWindowS,
      projection: projection ?? this.projection,
      flatFrac: flatFrac ?? this.flatFrac,
      minVAbs: minVAbs ?? this.minVAbs,
      maxMinutes: clearMaxMinutes ? null : (maxMinutes ?? this.maxMinutes),
      vminPct: clearColorRange ? null : (vminPct ?? this.vminPct),
      vmaxPct: clearColorRange ? null : (vmaxPct ?? this.vmaxPct),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'smooth_window_s': smoothWindowS,
    'projection': projection,
    'flat_frac': flatFrac,
    'min_v_abs': minVAbs,
    'max_minutes': maxMinutes,
    // vminPct / vmaxPct 僅供前端渲染，不傳給後端
  };
}


