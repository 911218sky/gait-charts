part of 'dashboard_overview.dart';

/// FFT / periodogram 相關可調設定。
///
/// 設計目標：
/// - 讓前端能以「結構化」方式調整後端 `scipy.signal.periodogram` 的關鍵參數。
/// - 預設值與後端 Pydantic schema 保持一致，避免 UI/後端預設不一致造成困惑。
class FftPeriodogramParams {
  const FftPeriodogramParams({
    this.window = 'hann',
    this.detrend = FftDetrend.none,
    this.scaling = FftScaling.spectrum,
    this.minNfft = 512,
    this.padToPow2 = true,
    this.zeroPadFactor = 1.0,
    this.removeDc = false,
  });

  /// scipy.signal.periodogram 的 window 參數；例如 hann、hamming 等。
  final String window;

  /// FFT 前的 detrend 模式。
  final FftDetrend detrend;

  /// periodogram scaling 參數（spectrum 或 density）。
  final FftScaling scaling;

  /// 最小 FFT 點數；不足會自動補零。
  final int minNfft;

  /// 是否將 nfft 補到 2 的次方，利於加速。
  final bool padToPow2;

  /// 額外零填充倍率，例如 2.0 代表至少補到原長度兩倍。
  final double zeroPadFactor;

  /// FFT 前是否扣除平均值以移除 DC 成分。
  final bool removeDc;

  FftPeriodogramParams copyWith({
    String? window,
    FftDetrend? detrend,
    FftScaling? scaling,
    int? minNfft,
    bool? padToPow2,
    double? zeroPadFactor,
    bool? removeDc,
  }) {
    return FftPeriodogramParams(
      window: window ?? this.window,
      detrend: detrend ?? this.detrend,
      scaling: scaling ?? this.scaling,
      minNfft: minNfft ?? this.minNfft,
      padToPow2: padToPow2 ?? this.padToPow2,
      zeroPadFactor: zeroPadFactor ?? this.zeroPadFactor,
      removeDc: removeDc ?? this.removeDc,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'window': window,
    'detrend': detrend.apiValue,
    'scaling': scaling.apiValue,
    'min_nfft': minNfft,
    'pad_to_pow2': padToPow2,
    'zero_pad_factor': zeroPadFactor,
    'remove_dc': removeDc,
  };

  factory FftPeriodogramParams.fromJson(Map<String, dynamic> json) {
    final window = _stringValue(json['window']).trim();
    final minNfft = _toInt(json['min_nfft']);
    final zeroPadFactor = _toDouble(json['zero_pad_factor']);
    return FftPeriodogramParams(
      window: window.isEmpty ? 'hann' : window,
      detrend: FftDetrend.fromApiValue(_stringValue(json['detrend'])),
      scaling: FftScaling.fromApiValue(_stringValue(json['scaling'])),
      minNfft: minNfft <= 0 ? 512 : minNfft,
      padToPow2: _toBool(json['pad_to_pow2'], fallback: true),
      zeroPadFactor: zeroPadFactor.isFinite && zeroPadFactor >= 1.0
          ? zeroPadFactor
          : 1.0,
      removeDc: _toBool(json['remove_dc']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FftPeriodogramParams &&
          other.window == window &&
          other.detrend == detrend &&
          other.scaling == scaling &&
          other.minNfft == minNfft &&
          other.padToPow2 == padToPow2 &&
          other.zeroPadFactor == zeroPadFactor &&
          other.removeDc == removeDc;

  @override
  int get hashCode => Object.hash(
        window,
        detrend,
        scaling,
        minNfft,
        padToPow2,
        zeroPadFactor,
        removeDc,
      );

  @override
  String toString() {
    return 'FftPeriodogramParams('
        'window: $window, detrend: ${detrend.apiValue}, '
        'scaling: ${scaling.apiValue}, minNfft: $minNfft, '
        'padToPow2: $padToPow2, zeroPadFactor: $zeroPadFactor, '
        'removeDc: $removeDc)';
  }
}

/// FFT 前的 detrend 模式（對應後端字串值）。
enum FftDetrend {
  none,
  constant,
  linear;

  String get apiValue => switch (this) {
        FftDetrend.none => 'none',
        FftDetrend.constant => 'constant',
        FftDetrend.linear => 'linear',
      };

  static FftDetrend fromApiValue(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'constant':
        return FftDetrend.constant;
      case 'linear':
        return FftDetrend.linear;
      case 'none':
      default:
        return FftDetrend.none;
    }
  }
}

/// periodogram scaling 參數（對應後端字串值）。
enum FftScaling {
  spectrum,
  density;

  String get apiValue => switch (this) {
        FftScaling.spectrum => 'spectrum',
        FftScaling.density => 'density',
      };

  static FftScaling fromApiValue(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'density':
        return FftScaling.density;
      case 'spectrum':
      default:
        return FftScaling.spectrum;
    }
  }
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}


