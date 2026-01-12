import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

import 'info_chip.dart';

/// 熱圖摘要資訊 chips，顯示寬度、圈數、色階範圍。
class SummaryChips extends StatelessWidget {
  const SummaryChips({
    required this.width,
    required this.laps,
    required this.vmin,
    required this.vmax,
    super.key,
  });

  final int width;
  final int laps;
  final double? vmin;
  final double? vmax;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final textStyle = textTheme.bodySmall?.copyWith(
      color: colors.onSurface.withValues(alpha: 0.72),
    );
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        InfoChip(label: '寬度', value: '$width'),
        InfoChip(label: '圈數', value: '$laps'),
        InfoChip(
          label: '色階下限',
          value: vmin?.toStringAsFixed(2) ?? 'auto',
          style: textStyle,
        ),
        InfoChip(
          label: '色階上限',
          value: vmax?.toStringAsFixed(2) ?? 'auto',
          style: textStyle,
        ),
      ],
    );
  }
}
