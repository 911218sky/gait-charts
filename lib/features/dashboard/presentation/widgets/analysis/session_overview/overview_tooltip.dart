import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// Tooltip 狀態資料。
class OverviewTooltipState {
  OverviewTooltipState({
    required this.lapIndex,
    required this.totalSeconds,
    required this.ratioPct,
    required this.stages,
    required this.position,
  });

  final int lapIndex;
  final double totalSeconds;
  final double ratioPct;
  final Map<String, double> stages;
  final Offset position;
}

/// 圖表 Tooltip 內容。
class OverviewTooltipContent extends StatelessWidget {
  const OverviewTooltipContent({
    required this.lapIndex,
    required this.totalSeconds,
    required this.ratioPct,
    required this.stages,
    super.key,
  });

  final int lapIndex;
  final double totalSeconds;
  final double ratioPct;
  final Map<String, double> stages;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lap $lapIndex',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '總耗時 ${totalSeconds.toStringAsFixed(2)} s',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '速度百分位 ${ratioPct.clamp(0, 100).toStringAsFixed(0)}%（越大越快）',
            style: TextStyle(
              color: colors.primary.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (stages.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final entry in stages.entries.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${entry.key}: ${entry.value.toStringAsFixed(2)} s',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.72),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 6),
          Text(
            '點選可跳到細節',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
