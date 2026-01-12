import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';

/// 圈數選擇器，以 Wrap 方式顯示所有圈數供使用者選擇。
class PerLapLapSelector extends ConsumerWidget {
  const PerLapLapSelector({required this.laps, super.key});

  final List<PerLapOffsetLap> laps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLap = ref.watch(perLapOffsetSelectedLapProvider);
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final textTheme = context.textTheme;

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
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '共 ${laps.length} 圈',
                  style: textTheme.bodySmall?.copyWith(
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
                return _LapChip(
                  lap: lap,
                  isSelected: isSelected,
                  isDark: isDark,
                  colors: colors,
                  onTap: () => ref
                      .read(perLapOffsetSelectedLapProvider.notifier)
                      .select(lap.lapIndex),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LapChip extends StatelessWidget {
  const _LapChip({
    required this.lap,
    required this.isSelected,
    required this.isDark,
    required this.colors,
    required this.onTap,
  });

  final PerLapOffsetLap lap;
  final bool isSelected;
  final bool isDark;
  final ColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lapDuration = lap.lapDurationSeconds;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : colors.primary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? null : Border.all(color: colors.outlineVariant),
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
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    'Lap ${lap.lapIndex}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                lapDuration > 0 ? '${lapDuration.toStringAsFixed(1)} s' : '--',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? (isDark
                          ? Colors.black54
                          : Colors.white.withValues(alpha: 0.7))
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
