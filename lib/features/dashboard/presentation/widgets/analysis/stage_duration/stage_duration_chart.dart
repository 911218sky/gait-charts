import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import 'stage_duration_bar_chart.dart';
import 'stage_duration_palette.dart';
import 'stage_duration_radar.dart';

/// 整合柱狀圖與雷達圖的單圈階段分析卡片。
class StageDurationChart extends StatelessWidget {
  const StageDurationChart({required this.selectedLap, super.key});

  final LapSummary selectedLap;

  @override
  Widget build(BuildContext context) {
    final stages = selectedLap.stages;
    final totalDuration = selectedLap.totalDurationSeconds > 0
        ? selectedLap.totalDurationSeconds
        : stages.fold<double>(0, (sum, stage) => sum + stage.durationSeconds);
    final radarEntries = [
      for (var i = 0; i < stages.length; i++)
        StageRadarEntry(
          label: stages[i].label,
          seconds: stages[i].durationSeconds,
          ratio: totalDuration <= 0
              ? 0
              : (stages[i].durationSeconds / totalDuration).clamp(0, 1),
          color: stageDurationPalette[i % stageDurationPalette.length],
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 雷達圖
            StageDurationRadar(
              entries: radarEntries,
              centerLabel: '總耗時',
              centerValue: '${totalDuration.toStringAsFixed(1)} s',
              title: '階段占比雷達圖',
              subtitle: '觀察單圈內每個階段耗時占總耗時的比例',
              height: 260,
              showLegend: true,
            ),
            const SizedBox(height: 32),
            Text(
              '階段耗時趨勢',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '每個階段的耗時（秒），距離資訊將以顏色與標籤呈現',
              style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
            ),
            // 柱狀圖
            StageDurationBarChart(
              stages: stages,
              totalDurationSeconds: totalDuration,
            ),
          ],
        ),
      ),
    );
  }
}
