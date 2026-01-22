import 'package:flutter/material.dart';

import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import 'stage_duration_palette.dart';
import 'stage_duration_pie_chart.dart';

/// 顯示整體平均階段占比的圓餅圖卡片。
class StageAverageRadarCard extends StatelessWidget {
  const StageAverageRadarCard({required this.analytics, super.key});

  final StageDurationsAnalytics? analytics;

  @override
  Widget build(BuildContext context) {
    final selectedAnalytics = analytics;
    final data = selectedAnalytics?.stageAverageDurations ?? const {};
    if (selectedAnalytics == null || data.isEmpty) {
      return const SizedBox.shrink();
    }

    final entriesList = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final total = entriesList.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );
    if (total <= 0) {
      return const SizedBox.shrink();
    }
    final pieEntries = [
      for (var i = 0; i < entriesList.length; i++)
        StagePieEntry(
          label: entriesList[i].key,
          seconds: entriesList[i].value,
          ratio: (entriesList[i].value / total).clamp(0, 1),
          color: stageDurationPalette[i % stageDurationPalette.length],
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StageDurationPieChart(
          entries: pieEntries,
          centerLabel: '平均單圈',
          centerValue:
              '${selectedAnalytics.averageLapDuration.toStringAsFixed(1)} s',
          title: '平均階段耗時占比',
          subtitle: '整合所有圈數後的平均耗時百分比',
          height: 240,
          showLegend: true,
        ),
      ),
    );
  }
}
