import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

import 'heatmap_color_scale.dart';

/// 熱圖色階圖例，顯示漸層色條與數值範圍。
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({
    required this.scale,
    required this.dataMin,
    required this.dataMax,
    super.key,
  });

  final HeatmapColorScale scale;
  final double? dataMin;
  final double? dataMax;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final minLabel = scale.min ?? dataMin;
    final maxLabel = scale.max ?? dataMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '色階 (m/s)',
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 200,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(colors: scale.palette.colors),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minLabel != null ? minLabel.toStringAsFixed(2) : 'auto',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            Text(
              maxLabel != null ? maxLabel.toStringAsFixed(2) : 'auto',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
