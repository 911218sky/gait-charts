import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';

/// 提供圈數 quick selection 的卡片。
class StageLapSelector extends ConsumerWidget {
  const StageLapSelector({required this.laps, super.key});

  final List<LapSummary> laps; // 所有圈數摘要

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLap = ref.watch(selectedLapIndexProvider);
    final colors = context.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '選擇要檢視的圈數',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '共 ${laps.length} 圈',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: laps.map((lap) {
                final isSelected = lap.lapIndex == selectedLap;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => ref
                        .read(selectedLapIndexProvider.notifier)
                        .select(lap.lapIndex),
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.onSurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? null
                            : Border.all(color: colors.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: colors.onInverseSurface,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                'Lap ${lap.lapIndex}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? colors.onInverseSurface
                                      : colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDuration(lap.totalDurationSeconds)} · ${lap.totalDistanceMeters.toStringAsFixed(2)} m',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? colors.onInverseSurface.withValues(alpha: 0.7)
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 將秒數格式化為 mm:ss。
String _formatDuration(double seconds) {
  if (seconds <= 0) {
    return '--';
  }
  final duration = Duration(milliseconds: (seconds * 1000).round());
  final minutes = duration.inMinutes;
  final secs = duration.inSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}
