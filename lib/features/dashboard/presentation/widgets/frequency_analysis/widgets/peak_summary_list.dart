import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/frequency_analysis/widgets/frequency_models.dart';

/// 峰值摘要列表，以 Chip 形式顯示各頻率系列的前幾個主要峰值
class PeakSummaryList extends StatelessWidget {
  const PeakSummaryList({required this.entries, super.key});

  final List<PeakSummaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final chips = <Widget>[];

    for (final entry in entries) {
      if (entry.peaks.isEmpty) continue;

      // 只顯示前 3 個峰值
      final highlights = entry.peaks.take(3).toList();
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12)),
            color: colors.onSurface.withValues(alpha: isDark ? 0.02 : 0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.label,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final peak in highlights)
                Text(
                  '${peak.freq.toStringAsFixed(2)} Hz / ${peak.db.toStringAsFixed(1)} dB',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peak 摘要',
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: chips),
      ],
    );
  }
}
