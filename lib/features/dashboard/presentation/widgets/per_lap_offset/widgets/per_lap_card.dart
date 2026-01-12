import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import 'chart_components.dart';
import 'lat_series_chart.dart';
import 'theta_chart.dart';

/// 單圈詳細資訊卡片，包含統計數據和圖表。
class PerLapCard extends StatelessWidget {
  const PerLapCard({
    required this.lap,
    required this.accent,
    required this.showSamples,
    required this.sampleLimit,
    required this.seriesMaxPoints,
    required this.thetaMaxPoints,
    super.key,
  });

  final PerLapOffsetLap lap;
  final DashboardAccentColors accent;
  final bool showSamples;
  final int? sampleLimit;
  final int seriesMaxPoints;
  final int thetaMaxPoints;

  @override
  Widget build(BuildContext context) {
    final lapDuration = lap.lapDurationSeconds;
    final walkDuration = lap.walkDurationSeconds;
    final textTheme = context.textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lap ${lap.lapIndex.toString().padLeft(2, '0')}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatChip(
                  label: '圈長',
                  value: lapDuration > 0
                      ? '${lapDuration.toStringAsFixed(1)} s'
                      : '--',
                  color: accent.success,
                ),
                StatChip(
                  label: '走路區段',
                  value: walkDuration > 0
                      ? '${walkDuration.toStringAsFixed(1)} s'
                      : '--',
                  color: accent.warning,
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final charts = [
                  LatSeriesChart(
                    lap: lap,
                    showSamples: showSamples,
                    sampleLimit: sampleLimit,
                    maxPoints: seriesMaxPoints,
                  ),
                  ThetaChart(
                    lap: lap,
                    showSamples: showSamples,
                    sampleLimit: sampleLimit,
                    maxPoints: thetaMaxPoints,
                  ),
                ];

                // 寬螢幕時並排顯示
                if (constraints.maxWidth >= 1500) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: charts[0]),
                      const SizedBox(width: 16),
                      Expanded(child: charts[1]),
                    ],
                  );
                }

                // 一般寬度時垂直排列
                return Column(
                  children: [
                    charts[0],
                    const SizedBox(height: 16),
                    charts[1],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
