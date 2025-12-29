import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/y_height_diff_chart.dart';

/// 顯示高度差統計的卡片列。
class YHeightDiffMetrics extends StatelessWidget {
  const YHeightDiffMetrics({
    required this.response,
    required this.unit,
    super.key,
  });

  final YHeightDiffResponse response;
  final HeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final accent = DashboardAccentColors.of(context);
    final stats = _YHeightStats.fromResponse(response);
    final scale = unit == HeightUnit.cm ? 100 : 1;
    final unitLabel = unit.label;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
          title: '最大高度差 (|L-R|)',
          value: '${(stats.maxAbsDiff * scale).toStringAsFixed(2)} $unitLabel',
          color: accent.danger,
        ),
        _MetricCard(
          title: '平均高度差',
          value: '${(stats.meanDiff * scale).toStringAsFixed(3)} $unitLabel',
          color: accent.warning,
        ),
        _MetricCard(
          title: '左/右平均高度',
          value:
              '${(stats.meanLeft * scale).toStringAsFixed(3)} $unitLabel / '
              '${(stats.meanRight * scale).toStringAsFixed(3)} $unitLabel',
          color: accent.success,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 320),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: context.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YHeightStats {
  _YHeightStats({
    required this.maxAbsDiff,
    required this.meanDiff,
    required this.meanLeft,
    required this.meanRight,
  });

  final double maxAbsDiff;
  final double meanDiff;
  final double meanLeft;
  final double meanRight;

  factory _YHeightStats.fromResponse(YHeightDiffResponse response) {
    final length = [
      response.left.length,
      response.right.length,
      response.diff.length,
    ].reduce((value, element) => value < element ? value : element);
    if (length == 0) {
      return _YHeightStats(
        maxAbsDiff: 0,
        meanDiff: 0,
        meanLeft: 0,
        meanRight: 0,
      );
    }
    double sumLeft = 0;
    double sumRight = 0;
    double sumDiff = 0;
    double maxAbs = 0;
    for (var i = 0; i < length; i++) {
      final l = response.left[i];
      final r = response.right[i];
      final d = response.diff[i];
      sumLeft += l;
      sumRight += r;
      sumDiff += d;
      maxAbs = (d.abs() > maxAbs) ? d.abs() : maxAbs;
    }
    return _YHeightStats(
      maxAbsDiff: maxAbs,
      meanDiff: sumDiff / length,
      meanLeft: sumLeft / length,
      meanRight: sumRight / length,
    );
  }
}
