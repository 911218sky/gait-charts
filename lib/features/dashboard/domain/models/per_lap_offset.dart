part of 'dashboard_overview.dart';

/// 將時間軸平移至 0 起點，方便比較。
List<double> _normalizeTime(List<double> source) {
  if (source.isEmpty) {
    return const [];
  }
  final origin = source.first;
  return source.map((value) => value - origin).toList();
}

/// 每圈 lateral offset 與頻譜分析回應。
class PerLapOffsetResponse {
  const PerLapOffsetResponse({required this.laps});

  final List<PerLapOffsetLap> laps;

  bool get isEmpty => laps.isEmpty;

  static const empty = PerLapOffsetResponse(laps: []);

  factory PerLapOffsetResponse.fromJson(Map<String, dynamic> json) {
    final lapsJson = json['laps'];
    if (lapsJson is List) {
      final parsed = <PerLapOffsetLap>[];
      for (final item in lapsJson) {
        if (item is Map<String, dynamic>) {
          parsed.add(PerLapOffsetLap.fromJson(item));
        } else if (item is Map) {
          parsed.add(PerLapOffsetLap.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return PerLapOffsetResponse(laps: parsed);
    }
    return PerLapOffsetResponse.empty;
  }
}

/// 單圈 lateral offset 與頻譜資料。
class PerLapOffsetLap {
  PerLapOffsetLap({
    required this.lapIndex,
    required this.timeSeconds,
    required this.latRaw,
    required this.latSmooth,
    required this.thetaDegrees,
    required this.coneTurn,
    required this.chairTurn,
    required this.walkRegion,
    required this.fft,
  });

  final int lapIndex;
  final List<double> timeSeconds;
  final List<double> latRaw;
  final List<double> latSmooth;
  final List<double> thetaDegrees;
  final LapRegion coneTurn;
  final LapRegion chairTurn;
  final LapRegion walkRegion;
  final PerLapOffsetFft fft;

  double get lapDurationSeconds =>
      timeSeconds.isEmpty ? 0 : timeSeconds.last - timeSeconds.first;

  double get walkDurationSeconds {
    if (timeSeconds.isEmpty) {
      return 0;
    }
    final start = walkRegion.startIndex.clamp(0, timeSeconds.length - 1);
    final end = walkRegion.endIndex.clamp(0, timeSeconds.length - 1);
    if (end <= start) {
      return 0;
    }
    return timeSeconds[end] - timeSeconds[start];
  }

  factory PerLapOffsetLap.fromJson(Map<String, dynamic> json) {
    final times = _normalizeTime(_toF32ZlibB64DecodedList(json['time_s_f32_zlib_b64']));
    final latRaw = _toF32ZlibB64DecodedList(json['lat_raw_f32_zlib_b64']);
    final latSmooth = _toF32ZlibB64DecodedList(json['lat_smooth_f32_zlib_b64']);
    final theta = _toF32ZlibB64DecodedList(json['theta_deg_f32_zlib_b64']);

    LapRegion regionFrom(dynamic value) {
      if (value is Map<String, dynamic>) {
        return LapRegion.fromJson(value);
      }
      if (value is Map) {
        return LapRegion.fromJson(Map<String, dynamic>.from(value));
      }
      return const LapRegion();
    }

    final turnRegions = json['turn_regions'] is Map<String, dynamic>
        ? json['turn_regions'] as Map<String, dynamic>
        : json['turn_regions'] is Map
        ? Map<String, dynamic>.from(json['turn_regions'] as Map)
        : null;
    final coneRegion = regionFrom(
      turnRegions != null ? turnRegions['cone'] : null,
    );
    final chairRegion = regionFrom(
      turnRegions != null ? turnRegions['chair'] : null,
    );
    final walkRegion = regionFrom(json['walk_region']);

    return PerLapOffsetLap(
      lapIndex: _toInt(json['lap_index']),
      timeSeconds: times,
      latRaw: latRaw,
      latSmooth: latSmooth,
      thetaDegrees: theta,
      coneTurn: coneRegion.normalize(times.length),
      chairTurn: chairRegion.normalize(times.length),
      walkRegion: walkRegion.normalize(times.length),
      fft: PerLapOffsetFft.fromJson(
        json['fft'] is Map<String, dynamic>
            ? json['fft'] as Map<String, dynamic>
            : json['fft'] is Map
            ? Map<String, dynamic>.from(json['fft'] as Map)
            : const <String, dynamic>{},
      ),
    );
  }
}

/// 表示圈內特定區段的索引範圍。
class LapRegion {
  const LapRegion({this.startIndex = 0, this.endIndex = 0});

  final int startIndex;
  final int endIndex;

  bool get isValid => endIndex >= startIndex;

  factory LapRegion.fromJson(Map<String, dynamic> json) {
    return LapRegion(
      startIndex: _toInt(json['start_idx']),
      endIndex: _toInt(json['end_idx']),
    );
  }

  /// 正規化索引範圍，確保 startIndex 小於 endIndex。
  LapRegion normalize(int length) {
    if (length <= 0) {
      return const LapRegion();
    }
    final maxIndex = length - 1;
    final normalizedStart = startIndex.clamp(0, maxIndex).toInt();
    final normalizedEnd = endIndex.clamp(0, maxIndex).toInt();
    if (normalizedEnd < normalizedStart) {
      return LapRegion(startIndex: normalizedEnd, endIndex: normalizedStart);
    }
    return LapRegion(startIndex: normalizedStart, endIndex: normalizedEnd);
  }
}

/// 儲存 FFT / PSD 相關的頻譜資訊。
class PerLapOffsetFft {
  const PerLapOffsetFft({
    required this.band,
    required this.frequencyHz,
    required this.psdDb,
    required this.peakFreqHz,
    required this.peakPower,
    required this.peakDb,
  });

  final List<double> band;
  final List<double> frequencyHz;
  final List<double> psdDb;
  final double peakFreqHz;
  final double peakPower;
  final double peakDb;

  double? get peakFrequencyOrNull => peakFreqHz.isFinite ? peakFreqHz : null;

  double? get peakDbOrNull => peakDb.isFinite ? peakDb : null;

  factory PerLapOffsetFft.fromJson(Map<String, dynamic> json) {
    final bandList = _toDoubleList(json['band']);
    final freq = _toF32ZlibB64DecodedList(json['freq_hz_f32_zlib_b64']);
    final psd = _toF32ZlibB64DecodedList(json['psd_db_f32_zlib_b64']);

    return PerLapOffsetFft(
      band: bandList.length >= 2 ? bandList.sublist(0, 2) : const [0, 0],
      frequencyHz: freq,
      psdDb: psd,
      peakFreqHz: _toDouble(json['peak_freq_hz']),
      peakPower: _toDouble(json['peak_power']),
      peakDb: _toDouble(json['peak_db']),
    );
  }
}

/// per-lap offset API 查詢設定。
class PerLapOffsetConfig {
  const PerLapOffsetConfig({
    this.projection = 'xz',
    this.smoothWindow = 3,
    this.minVAbs = 15,
    this.flatFrac = 0.7,
    this.kSmooth = 1,
    this.fftBandLow = 0,
    this.fftBandHigh = 2,
    this.fftParams = const FftPeriodogramParams(),
  });

  final String projection;
  final int smoothWindow;
  final double minVAbs;
  final double flatFrac;
  final int kSmooth;
  final double fftBandLow;
  final double fftBandHigh;
  final FftPeriodogramParams fftParams;

  PerLapOffsetConfig copyWith({
    String? projection,
    int? smoothWindow,
    double? minVAbs,
    double? flatFrac,
    int? kSmooth,
    double? fftBandLow,
    double? fftBandHigh,
    FftPeriodogramParams? fftParams,
  }) {
    var low = fftBandLow ?? this.fftBandLow;
    var high = fftBandHigh ?? this.fftBandHigh;
    if (low > high) {
      final temp = low;
      low = high;
      high = temp;
    }
    return PerLapOffsetConfig(
      projection: projection ?? this.projection,
      smoothWindow: smoothWindow ?? this.smoothWindow,
      minVAbs: minVAbs ?? this.minVAbs,
      flatFrac: flatFrac ?? this.flatFrac,
      kSmooth: kSmooth ?? this.kSmooth,
      fftBandLow: low,
      fftBandHigh: high,
      fftParams: fftParams ?? this.fftParams,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'projection': projection,
    'smooth_window_s': smoothWindow,
    'min_v_abs': minVAbs,
    'flat_frac': flatFrac,
    'k_smooth': kSmooth,
    'fft_band': [fftBandLow, fftBandHigh],
    'fft_params': fftParams.toJson(),
  };

  @override
  String toString() {
    return 'PerLapOffsetConfig('
        'projection: $projection, smoothWindow: $smoothWindow, '
        'minVAbs: $minVAbs, flatFrac: $flatFrac, '
        'kSmooth: $kSmooth, fftBand: [$fftBandLow, $fftBandHigh], '
        'fftParams: $fftParams)';
  }
}
