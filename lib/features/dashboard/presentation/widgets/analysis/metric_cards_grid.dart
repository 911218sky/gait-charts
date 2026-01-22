import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// 顯示統計數據卡片的彈性網格。
class MetricCardsGrid extends StatelessWidget {
  const MetricCardsGrid({
    required this.analytics,
    required this.accent,
    super.key,
  });

  final StageDurationsAnalytics? analytics; // 統計分析資料
  final DashboardAccentColors accent; // 強調色設定

  @override
  Widget build(BuildContext context) {
    final data = analytics;
    if (data == null || data.totalLaps == 0) {
      final colors = context.colorScheme;
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.cardColor,
          border: Border.all(color: context.dividerColor),
        ),
        child: Text(
          '尚未計算統計資料。',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    // 將階段耗時排序，找出耗時最長的階段
    final stageAverageEntries = data.stageAverageDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // 根據寬度決定欄數：手機版 1 欄，平板 2-3 欄，桌面 4 欄
        final columns = availableWidth > 1000
            ? 4
            : availableWidth > 720
            ? 3
            : availableWidth > 500
            ? 2
            : 1;

        final cards = [
          _MetricCard(
            label: '分析圈數',
            value: data.totalLaps.toString(),
            subtitle: '成功偵測的復健圈數',
            icon: Icons.all_inclusive,
            color: accent.success,
          ),
          _MetricCard(
            label: '平均圈速',
            value: _formatDuration(data.averageLapDuration),
            subtitle: '每圈平均耗時',
            icon: Icons.schedule,
            color: accent.warning,
          ),
          _MetricCard(
            label: '最快圈',
            value: _formatDuration(data.fastestLapDuration),
            subtitle: '最佳單圈耗時',
            icon: Icons.flash_on,
            color: accent.success,
          ),
          _MetricCard(
            label: '總行走距離',
            value: '${data.totalDistanceMeters.toStringAsFixed(1)} m',
            subtitle: '所有圈的總合',
            icon: Icons.route,
            color: accent.danger,
          ),
        ];

        if (stageAverageEntries.isNotEmpty) {
          final topStage = stageAverageEntries.first;
          cards.add(
            _MetricCard(
              label: '耗時最多的階段',
              value: _formatDuration(topStage.value),
              subtitle: topStage.key,
              icon: Icons.timelapse,
              color: accent.warning,
            ),
          );
        }

        final cardWidth = ((availableWidth - 16 * (columns - 1)) / columns)
            .clamp(220.0, 400.0);

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }
}

/// 單一數據卡片元件。
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 20),
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 將秒數轉成 mm:ss.hh 文字。
String _formatDuration(double seconds) {
  if (seconds <= 0) {
    return '--';
  }
  final duration = Duration(milliseconds: (seconds * 1000).round());
  final minutes = duration.inMinutes;
  final secs = duration.inSeconds.remainder(60);
  final hundreds = (duration.inMilliseconds.remainder(1000) / 10).round();
  return '${minutes.toString().padLeft(2, '0')}:'
      '${secs.toString().padLeft(2, '0')}.'
      '${hundreds.toString().padLeft(2, '0')}';
}
