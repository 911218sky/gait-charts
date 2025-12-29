part of 'dashboard_overview.dart';

/// /spatial_spectrum API 的回應資料。
class SpatialSpectrumResponse {
  const SpatialSpectrumResponse({required this.series});

  final List<SpatialSpectrumSeries> series;

  bool get isEmpty => series.isEmpty;

  static const empty = SpatialSpectrumResponse(series: []);

  factory SpatialSpectrumResponse.fromJson(Map<String, dynamic> json) {
    final spectrums = json['spectrums'];
    if (spectrums is! List) {
      return SpatialSpectrumResponse.empty;
    }
    final parsed = <SpatialSpectrumSeries>[];
    for (final item in spectrums) {
      if (item is Map<String, dynamic>) {
        parsed.add(SpatialSpectrumSeries.fromJson(item));
      } else if (item is Map) {
        parsed.add(
          SpatialSpectrumSeries.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    return SpatialSpectrumResponse(series: parsed);
  }
}

/// 單條空間頻譜曲線。
class SpatialSpectrumSeries {
  const SpatialSpectrumSeries({
    required this.pair,
    required this.frequencyHz,
    required this.psdDb,
    required this.peaks,
  });

  final String pair;
  final List<double> frequencyHz;
  final List<double> psdDb;
  final List<SpatialSpectrumPeak> peaks;

  String get label => pair.toUpperCase();

  bool get hasData => frequencyHz.isNotEmpty && psdDb.isNotEmpty;

  factory SpatialSpectrumSeries.fromJson(Map<String, dynamic> json) {
    final peaksJson = json['peaks'];
    final peaks = <SpatialSpectrumPeak>[];
    if (peaksJson is List) {
      for (final item in peaksJson) {
        if (item is Map<String, dynamic>) {
          peaks.add(SpatialSpectrumPeak.fromJson(item));
        } else if (item is Map) {
          peaks.add(
            SpatialSpectrumPeak.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return SpatialSpectrumSeries(
      pair: _stringValue(json['pair']).toLowerCase(),
      frequencyHz: _toF32ZlibB64DecodedList(json['freq_f32_zlib_b64']),
      psdDb: _toF32ZlibB64DecodedList(json['psd_db_f32_zlib_b64']),
      peaks: peaks,
    );
  }
}

/// 頻譜峰值資訊。
class SpatialSpectrumPeak {
  const SpatialSpectrumPeak({required this.freqHz, required this.db});

  final double freqHz;
  final double db;

  factory SpatialSpectrumPeak.fromJson(Map<String, dynamic> json) {
    return SpatialSpectrumPeak(
      freqHz: _toDouble(json['freq']),
      db: _toDouble(json['db']),
    );
  }
}

/// spatial_spectrum API 查詢設定。
class SpatialSpectrumConfig {
  const SpatialSpectrumConfig({
    this.pairs = const ['xz'],
    this.kSmooth = 2,
    this.topK = 3,
    this.minPeakDistanceRatio = 0.01,
    this.minDb = -60,
    this.minFreq = 0.5,
  });

  /// 要分析的 pair（xz / yz）
  final List<String> pairs;

  /// 平滑係數
  final int kSmooth;

  /// 每條曲線最多標註峰數，null 表示不限制
  final int? topK;

  /// 峰間最小距比例
  final double minPeakDistanceRatio;

  /// 峰值最低 dB
  final double minDb;

  /// 最低頻率
  final double minFreq;

  SpatialSpectrumConfig copyWith({
    List<String>? pairs,
    int? kSmooth,
    int? topK,
    bool clearTopK = false,
    double? minPeakDistanceRatio,
    double? minDb,
    double? minFreq,
  }) {
    final sanitizedPairs = pairs == null ? this.pairs : _sanitizePairs(pairs);
    final resolvedPairs = sanitizedPairs.isEmpty ? this.pairs : sanitizedPairs;
    return SpatialSpectrumConfig(
      pairs: List<String>.unmodifiable(resolvedPairs),
      kSmooth: kSmooth ?? this.kSmooth,
      topK: clearTopK ? null : (topK ?? this.topK),
      minPeakDistanceRatio: minPeakDistanceRatio ?? this.minPeakDistanceRatio,
      minDb: minDb ?? this.minDb,
      minFreq: minFreq ?? this.minFreq,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'pair': pairs,
    'k_smooth': kSmooth,
    if (topK != null) 'top_k': topK,
    'min_peak_distance_ratio': minPeakDistanceRatio,
    'min_db': minDb,
    'min_freq': minFreq,
  };
}

/// 將使用者輸入的 pair 名稱正規化成小寫且過濾空白字串，避免 API 參數不一致。
List<String> _sanitizePairs(List<String> values) {
  return values
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}
