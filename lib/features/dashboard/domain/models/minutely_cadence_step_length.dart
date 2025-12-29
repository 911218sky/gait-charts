part of 'dashboard_overview.dart';

/// 封裝每分鐘步頻與步長柱狀圖的請求設定。
class MinutelyCadenceStepLengthBarsConfig {
  const MinutelyCadenceStepLengthBarsConfig({
    this.projection = 'xz',
    this.smoothWindow = 3,
    this.minVAbs = 15,
    this.flatFrac = 0.7,
    this.maxMinutes,
  });

  final String projection;
  final int smoothWindow;
  final double minVAbs;
  final double flatFrac;
  final int? maxMinutes;

  MinutelyCadenceStepLengthBarsConfig copyWith({
    String? projection,
    int? smoothWindow,
    double? minVAbs,
    double? flatFrac,
    int? maxMinutes,
  }) {
    return MinutelyCadenceStepLengthBarsConfig(
      projection: projection ?? this.projection,
      smoothWindow: smoothWindow ?? this.smoothWindow,
      minVAbs: minVAbs ?? this.minVAbs,
      flatFrac: flatFrac ?? this.flatFrac,
      maxMinutes: maxMinutes ?? this.maxMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'projection': projection,
      'smooth_window_s': smoothWindow,
      'min_v_abs': minVAbs,
      'flat_frac': flatFrac,
      if (maxMinutes != null) 'max_minutes': maxMinutes,
    };
  }
}

/// 從 API 回傳的每分鐘步頻 / 步長 / 步數資料。
class MinutelyCadenceStepLengthBarsResponse {
  const MinutelyCadenceStepLengthBarsResponse({
    required this.minutes,
    required this.cadenceSpm,
    required this.stepLengthMeters,
    required this.stepCounts,
  });

  final List<int> minutes;
  final List<double> cadenceSpm;
  final List<double> stepLengthMeters;
  final List<int> stepCounts;

  static const empty = MinutelyCadenceStepLengthBarsResponse(
    minutes: [],
    cadenceSpm: [],
    stepLengthMeters: [],
    stepCounts: [],
  );

  bool get isEmpty => minutes.isEmpty;

  factory MinutelyCadenceStepLengthBarsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    List<int> parseIntList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => int.tryParse('$e'))
            .whereType<int>()
            .toList(growable: false);
      }
      return const [];
    }

    List<double> parseDoubleList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => double.tryParse('$e'))
            .whereType<double>()
            .toList(growable: false);
      }
      return const [];
    }

    final minutes = parseIntList(json['minutes']);
    final cadence = parseDoubleList(json['cadence_spm']);
    final stepLength = parseDoubleList(json['step_length_m']);
    final stepCounts = parseIntList(json['step_counts']);

    return MinutelyCadenceStepLengthBarsResponse(
      minutes: minutes,
      cadenceSpm: cadence,
      stepLengthMeters: stepLength,
      stepCounts: stepCounts,
    );
  }

  /// 將原始陣列組合為每分鐘資料點，方便 UI 佈局。
  List<MinutelyCadencePoint> get points {
    final length = [
      minutes.length,
      cadenceSpm.length,
      stepLengthMeters.length,
      stepCounts.length,
    ].reduce((value, element) => value < element ? value : element);
    return List.generate(length, (index) {
      return MinutelyCadencePoint(
        minute: minutes[index],
        cadenceSpm: cadenceSpm[index],
        stepLengthMeters: stepLengthMeters[index],
        stepCount: stepCounts[index],
      );
    });
  }
}

/// UI 友善的每分鐘資料點。
class MinutelyCadencePoint {
  const MinutelyCadencePoint({
    required this.minute,
    required this.cadenceSpm,
    required this.stepLengthMeters,
    required this.stepCount,
  });

  final int minute;
  final double cadenceSpm;
  final double stepLengthMeters;
  final int stepCount;
}
