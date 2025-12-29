part of 'dashboard_overview.dart';

/// /multi_fft_from_series API 的回應資料。
class MultiFftSeriesResponse {
  const MultiFftSeriesResponse({required this.component, required this.series});

  final String component;
  final List<MultiFftSeries> series;

  bool get isEmpty => series.isEmpty;

  static const empty = MultiFftSeriesResponse(component: '', series: []);

  factory MultiFftSeriesResponse.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'];
    final component = _stringValue(json['component']).toLowerCase();
    if (rawSeries is! List) {
      return MultiFftSeriesResponse(component: component, series: const []);
    }
    final parsed = <MultiFftSeries>[];
    for (final item in rawSeries) {
      if (item is Map<String, dynamic>) {
        parsed.add(MultiFftSeries.fromJson(item));
      } else if (item is Map) {
        parsed.add(MultiFftSeries.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return MultiFftSeriesResponse(component: component, series: parsed);
  }
}

/// 單條 FFT / PSD 曲線。
class MultiFftSeries {
  const MultiFftSeries({
    required this.label,
    required this.jointSpec,
    required this.frequencyHz,
    required this.psdDb,
    required this.peaks,
  });

  final String label;
  final Object? jointSpec;
  final List<double> frequencyHz;
  final List<double> psdDb;
  final List<MultiFftPeak> peaks;

  bool get hasData => frequencyHz.isNotEmpty && psdDb.isNotEmpty;

  MultiFftSeries copyWith({String? label}) {
    return MultiFftSeries(
      label: label ?? this.label,
      jointSpec: jointSpec,
      frequencyHz: frequencyHz,
      psdDb: psdDb,
      peaks: peaks,
    );
  }

  factory MultiFftSeries.fromJson(Map<String, dynamic> json) {
    final jointSpec = json['joint_spec'];
    final peaksJson = json['peaks'];
    final peaks = <MultiFftPeak>[];
    if (peaksJson is List) {
      for (final item in peaksJson) {
        if (item is Map<String, dynamic>) {
          peaks.add(MultiFftPeak.fromJson(item));
        } else if (item is Map) {
          peaks.add(MultiFftPeak.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return MultiFftSeries(
      label: _describeJointSpec(jointSpec),
      jointSpec: jointSpec,
      frequencyHz: _toF32ZlibB64DecodedList(json['freq_hz_f32_zlib_b64']),
      psdDb: _toF32ZlibB64DecodedList(json['psd_db_f32_zlib_b64']),
      peaks: peaks,
    );
  }
}

/// 頻譜峰值描述。
class MultiFftPeak {
  const MultiFftPeak({required this.freqHz, required this.db});

  final double freqHz;
  final double db;

  factory MultiFftPeak.fromJson(Map<String, dynamic> json) {
    return MultiFftPeak(
      freqHz: _toDouble(json['freq_hz']),
      db: _toDouble(json['db']),
    );
  }
}

/// 定義 multi FFT 的關節選取。
class MultiFftJointSelection {
  const MultiFftJointSelection({
    required this.id,
    required this.label,
    required this.spec,
  });

  final String id;
  final String label;
  final Object spec;

  MultiFftJointSelection copyWith({String? id, String? label, Object? spec}) {
    return MultiFftJointSelection(
      id: id ?? this.id,
      label: label ?? this.label,
      spec: spec ?? this.spec,
    );
  }
}

const MultiFftJointSelection kMultiFftJointPelvis = MultiFftJointSelection(
  id: 'pelvis',
  label: '骨盆中心 (#23/#24)',
  spec: [23, 24], // left_hip / right_hip
);

const MultiFftJointSelection kMultiFftJointShoulder = MultiFftJointSelection(
  id: 'shoulder',
  label: '肩帶 (#11/#12)',
  spec: [11, 12], // left_shoulder / right_shoulder
);

const MultiFftJointSelection kMultiFftJointAnkle = MultiFftJointSelection(
  id: 'ankle',
  label: '踝部 (#27/#28)',
  spec: [27, 28], // left_ankle / right_ankle
);

const MultiFftJointSelection kMultiFftJointLeftKnee = MultiFftJointSelection(
  id: 'left_knee',
  label: '左膝 (#25)',
  spec: 25,
);

const MultiFftJointSelection kMultiFftJointRightKnee = MultiFftJointSelection(
  id: 'right_knee',
  label: '右膝 (#26)',
  spec: 26,
);

const List<MultiFftJointSelection> kMultiFftJointPresets = [
  kMultiFftJointPelvis,
  kMultiFftJointShoulder,
  kMultiFftJointAnkle,
  kMultiFftJointLeftKnee,
  kMultiFftJointRightKnee,
];

const List<MultiFftJointSelection> kDefaultMultiFftJointSelections = [
  kMultiFftJointPelvis,
];

/// multi_fft_from_series API 查詢設定。
class MultiFftFromSeriesConfig {
  const MultiFftFromSeriesConfig({
    this.component = 'z',
    this.topK = 3,
    this.minPeakDistanceRatio = 0.01,
    this.minDb = -60,
    this.minFreq = 0.05,
    this.joints = kDefaultMultiFftJointSelections,
    this.fftParams = const FftPeriodogramParams(),
  });

  /// 使用的軸 x/y/z
  final String component;

  /// 每條曲線最多標註峰數，null 表示不限制
  final int? topK;

  /// 峰間最小距比例
  final double minPeakDistanceRatio;

  /// 峰值最低 dB
  final double minDb;

  /// 最低頻率
  final double minFreq;

  /// 關節選取
  final List<MultiFftJointSelection> joints;

  /// FFT / periodogram 進階參數（window、nfft、zero-pad 等）
  final FftPeriodogramParams fftParams;

  MultiFftFromSeriesConfig copyWith({
    String? component,
    int? topK,
    bool clearTopK = false,
    double? minPeakDistanceRatio,
    double? minDb,
    double? minFreq,
    List<MultiFftJointSelection>? joints,
    FftPeriodogramParams? fftParams,
  }) {
    final sanitizedJoints = joints == null || joints.isEmpty
        ? this.joints
        : joints;
    return MultiFftFromSeriesConfig(
      component: (component ?? this.component).toLowerCase(),
      topK: clearTopK ? null : (topK ?? this.topK),
      minPeakDistanceRatio: minPeakDistanceRatio ?? this.minPeakDistanceRatio,
      minDb: minDb ?? this.minDb,
      minFreq: minFreq ?? this.minFreq,
      joints: List<MultiFftJointSelection>.unmodifiable(sanitizedJoints),
      fftParams: fftParams ?? this.fftParams,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'component': component.toLowerCase(),
    if (topK != null) 'top_k': topK,
    'min_peak_distance_ratio': minPeakDistanceRatio,
    'min_db': minDb,
    'min_freq': minFreq,
    'joints': joints.map((entry) => entry.spec).toList(growable: false),
    'fft_params': fftParams.toJson(),
  };
}

String _describeJointSpec(dynamic spec) {
  if (spec is String) {
    return spec;
  }
  if (spec is int) {
    return 'Joint $spec';
  }
  if (spec is List) {
    final labels = spec.map(_stringValue).toList();
    return labels.join(' + ');
  }
  return 'Joint';
}
