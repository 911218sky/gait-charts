import 'package:fl_chart/fl_chart.dart';

/// 共用的點樣式判斷：只有點數較少時才描邊，避免大量點把線條蓋黑。
bool shouldShowDotStroke({
  int? sampleLimit,
  List<FlSpot>? spots,
  int threshold = 300,
}) {
  // 未提供 sampleLimit、也沒有 spots 可推估時，預設不描邊（避免意外出現黑框）。
  if (sampleLimit == null && (spots == null || spots.isEmpty)) {
    return false;
  }
  final count = sampleLimit ?? spots?.length ?? 0;
  return count <= threshold;
}