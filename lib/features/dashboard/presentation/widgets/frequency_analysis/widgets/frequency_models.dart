import 'package:flutter/material.dart';

/// 頻率圖表的單一資料系列，包含 X/Y 軸數據及峰值標記
class FrequencySeries {
  FrequencySeries({
    required this.label,
    required this.xValues,
    required this.yValues,
    required this.color,
    required this.peaks,
  });

  final String label;

  /// X 軸數值 (通常為頻率 Hz)
  final List<double> xValues;

  /// Y 軸數值 (通常為振幅 dB)
  final List<double> yValues;

  /// 該系列中偵測到的峰值點
  final List<FrequencyPeak> peaks;
  final Color color;

  bool get hasData => xValues.isNotEmpty && yValues.isNotEmpty;
}

/// 頻譜峰值資料，記錄頻率 (Hz) 與振幅 (dB)
class FrequencyPeak {
  const FrequencyPeak({required this.freq, required this.db});

  final double freq;
  final double db;
}

/// 峰值摘要項目，用於 [PeakSummaryList] 顯示
class PeakSummaryEntry {
  const PeakSummaryEntry({
    required this.label,
    required this.color,
    required this.peaks,
  });

  final String label;
  final Color color;
  final List<FrequencyPeak> peaks;
}
