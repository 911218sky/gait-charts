import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/benchmark_radar.dart';

/// 總覽卡片。
///
/// 以卡片形式包裝 [BenchmarkRadar] 雷達圖，用於顯示各類指標的總覽。
/// 常用於 Overview 頁面中展示 Lap Time、Gait、Speed 等分類的雷達圖。
class OverviewCard extends StatelessWidget {
  const OverviewCard({
    required this.title,
    required this.entries,
    super.key,
  });

  /// 卡片標題（如 'Lap Time', 'Gait', 'Speed'）
  final String title;

  /// 雷達圖的資料項目
  final List<BenchmarkRadarEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: context.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BenchmarkRadar(
            title: title,
            subtitle: '雷達圖：使用者相對族群的表現（100% = 族群基準）',
            entries: entries,
            height: 300,
          ),
        ],
      ),
    );
  }
}
