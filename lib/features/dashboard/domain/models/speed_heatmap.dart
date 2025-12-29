part of 'dashboard_overview.dart';

/// 每圈速度時空熱圖的回應資料。
class SpeedHeatmapResponse {
  const SpeedHeatmapResponse({
    required this.width,
    required this.heatmap,
    required this.marks,
  });

  /// 重採樣後的寬度（每圈點數）。
  final int width;

  /// 速度矩陣，row = lap-1, col = 進度索引。
  final List<List<double?>> heatmap;

  /// 各圈的轉身區段標註（可能同時包含 cone / chair 兩段）。
  final List<SpeedHeatmapMark> marks;

  bool get isEmpty => heatmap.isEmpty;

  int get lapCount => heatmap.length;

  /// 資料中的最小值（忽略 null/NaN）。
  double? get dataMin => _foldFinite(
    (current, next) => current == null
        ? next
        : current < next
        ? current
        : next,
  );

  /// 資料中的最大值（忽略 null/NaN）。
  double? get dataMax => _foldFinite(
    (current, next) => current == null
        ? next
        : current > next
        ? current
        : next,
  );

  static const empty = SpeedHeatmapResponse(
    width: 0,
    heatmap: [],
    marks: [],
  );

  factory SpeedHeatmapResponse.fromJson(Map<String, dynamic> json) {
    final rawHeatmap = json['heatmap'];
    final parsedHeatmap = <List<double?>>[];
    if (rawHeatmap is List) {
      for (final row in rawHeatmap) {
        if (row is List) {
          parsedHeatmap.add(row.map<double?>(_toNullableDouble).toList());
        }
      }
    }

    // marks 目前後端可能有兩種格式：
    // 1) 一圈一筆：{lap_index, cone_start_frac, cone_end_frac, chair_start_frac?, chair_end_frac?}
    // 2) 一圈多筆：{lap_index, turn_type: 'cone'|'chair', start_frac, end_frac}
    // 甚至可能包在 turn_regions：{lap_index, turn_regions: {cone:{...}, chair:{...}}}
    // 這裡統一合併成「每圈一筆」，避免 UI 端因 key 重複而覆蓋掉其中一段。
    final marksJson = json['marks'];
    final parsedMarks = _parseAndMergeMarks(marksJson);

    return SpeedHeatmapResponse(
      width: _toInt(json['width']),
      heatmap: parsedHeatmap,
      marks: parsedMarks,
    );
  }

  /// 將所有有限值折疊以取得 min/max。
  double? _foldFinite(double? Function(double? current, double next) combiner) {
    double? acc;
    for (final row in heatmap) {
      for (final value in row) {
        if (value == null || value.isNaN || value.isInfinite) {
          continue;
        }
        acc = combiner(acc, value);
      }
    }
    return acc;
  }
}

/// 轉身區段資訊（每圈一筆，可同時含 cone / chair 兩段）。
class SpeedHeatmapMark {
  const SpeedHeatmapMark({
    required this.lapIndex,
    this.coneStartFrac,
    this.coneEndFrac,
    this.chairStartFrac,
    this.chairEndFrac,
  });

  /// 圈次（1-based）。
  final int lapIndex;

  /// 錐桶轉身開始位置（相對圈長 0~1）。
  final double? coneStartFrac;

  /// 錐桶轉身結束位置（相對圈長 0~1）。
  final double? coneEndFrac;

  /// 椅子轉身開始位置（相對圈長 0~1）。
  final double? chairStartFrac;

  /// 椅子轉身結束位置（相對圈長 0~1）。
  final double? chairEndFrac;

  factory SpeedHeatmapMark.fromJson(Map<String, dynamic> json) {
    return SpeedHeatmapMark(
      lapIndex: _toInt(json['lap_index']),
      coneStartFrac:
          _toNullableDouble(json['cone_start_frac']) ??
          _toNullableDouble(json['coneStartFrac']),
      coneEndFrac:
          _toNullableDouble(json['cone_end_frac']) ??
          _toNullableDouble(json['coneEndFrac']),
      chairStartFrac: _toNullableDouble(json['chair_start_frac']),
      chairEndFrac: _toNullableDouble(json['chair_end_frac']),
    );
  }
}

/// speed_heatmap API 的查詢設定。
class SpeedHeatmapConfig {
  const SpeedHeatmapConfig({
    this.projection = 'xz',
    this.smoothWindow = 3,
    this.minVAbs = 15,
    this.flatFrac = 0.7,
    this.width = 300,
  });

  final String projection;
  final int smoothWindow;
  final double minVAbs;
  final double flatFrac;
  final int width;

  SpeedHeatmapConfig copyWith({
    String? projection,
    int? smoothWindow,
    double? minVAbs,
    double? flatFrac,
    int? width,
  }) {
    return SpeedHeatmapConfig(
      projection: projection ?? this.projection,
      smoothWindow: smoothWindow ?? this.smoothWindow,
      minVAbs: minVAbs ?? this.minVAbs,
      flatFrac: flatFrac ?? this.flatFrac,
      width: width ?? this.width,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'projection': projection,
    'smooth_window_s': smoothWindow,
    'min_v_abs': minVAbs,
    'flat_frac': flatFrac,
    'width': width,
  };
}

double? _toNullableDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

List<SpeedHeatmapMark> _parseAndMergeMarks(dynamic marksJson) {
  if (marksJson is! List) {
    return const <SpeedHeatmapMark>[];
  }

  // 以 lapIndex 合併，避免同圈多筆標註被覆蓋。
  final merged = <int, SpeedHeatmapMark>{};

  void upsert({
    required int lapIndex,
    double? coneStartFrac,
    double? coneEndFrac,
    double? chairStartFrac,
    double? chairEndFrac,
  }) {
    final existing = merged[lapIndex];
    merged[lapIndex] = SpeedHeatmapMark(
      lapIndex: lapIndex,
      coneStartFrac: coneStartFrac ?? existing?.coneStartFrac,
      coneEndFrac: coneEndFrac ?? existing?.coneEndFrac,
      chairStartFrac: chairStartFrac ?? existing?.chairStartFrac,
      chairEndFrac: chairEndFrac ?? existing?.chairEndFrac,
    );
  }

  Map<String, dynamic>? asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  for (final item in marksJson) {
    final map = asMap(item);
    if (map == null) continue;

    final lapIndex = _toInt(map['lap_index']);
    if (lapIndex <= 0) continue;

    // 格式 (1)：一圈一筆（cone/chair 直接在同一層）
    if (map.containsKey('cone_start_frac') ||
        map.containsKey('cone_end_frac') ||
        map.containsKey('chair_start_frac') ||
        map.containsKey('chair_end_frac')) {
      upsert(
        lapIndex: lapIndex,
        coneStartFrac: _toNullableDouble(map['cone_start_frac']),
        coneEndFrac: _toNullableDouble(map['cone_end_frac']),
        chairStartFrac: _toNullableDouble(map['chair_start_frac']),
        chairEndFrac: _toNullableDouble(map['chair_end_frac']),
      );
      continue;
    }

    // 格式 (1b)：turn_regions: { cone: {start_frac,end_frac}, chair: {...} }
    final turnRegions = asMap(map['turn_regions']);
    if (turnRegions != null) {
      final cone = asMap(turnRegions['cone']);
      if (cone != null) {
        upsert(
          lapIndex: lapIndex,
          coneStartFrac:
              _toNullableDouble(cone['start_frac']) ??
              _toNullableDouble(cone['start']),
          coneEndFrac:
              _toNullableDouble(cone['end_frac']) ??
              _toNullableDouble(cone['end']),
        );
      }
      final chair = asMap(turnRegions['chair']);
      if (chair != null) {
        upsert(
          lapIndex: lapIndex,
          chairStartFrac:
              _toNullableDouble(chair['start_frac']) ??
              _toNullableDouble(chair['start']),
          chairEndFrac:
              _toNullableDouble(chair['end_frac']) ??
              _toNullableDouble(chair['end']),
        );
      }
      continue;
    }

    // 格式 (2)：一圈多筆：{lap_index, turn_type, start_frac, end_frac}
    final type = _stringValue(
      map['turn_type'] ?? map['type'] ?? map['kind'],
    ).trim().toLowerCase();
    final start =
        _toNullableDouble(map['start_frac']) ??
        _toNullableDouble(map['start']) ??
        _toNullableDouble(map['startFrac']);
    final end =
        _toNullableDouble(map['end_frac']) ??
        _toNullableDouble(map['end']) ??
        _toNullableDouble(map['endFrac']);

    if (start == null || end == null) {
      continue;
    }

    if (type == 'cone' || type == 'turn_cone') {
      upsert(lapIndex: lapIndex, coneStartFrac: start, coneEndFrac: end);
    } else if (type == 'chair' || type == 'turn_chair') {
      upsert(lapIndex: lapIndex, chairStartFrac: start, chairEndFrac: end);
    }
  }

  final list = merged.values.toList()
    ..sort((a, b) => a.lapIndex.compareTo(b.lapIndex));
  return list;
}
