import 'package:fl_chart/fl_chart.dart';

/// 判斷圖表點是否需要描邊。
///
/// 點數較少時描邊可增加辨識度；點數過多時描邊會讓線條變黑。
bool shouldShowDotStroke({
  int? sampleLimit,
  List<FlSpot>? spots,
  int threshold = 300,
}) {
  // 無法推估點數時預設不描邊
  if (sampleLimit == null && (spots == null || spots.isEmpty)) {
    return false;
  }
  final count = sampleLimit ?? spots?.length ?? 0;
  return count <= threshold;
}