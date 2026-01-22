import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 圖表卡片容器，提供標題、副標題和圖例。
class LapChartCard extends StatelessWidget {
  const LapChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.legend,
    this.reserveLegendSpace = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<LegendEntry>? legend;
  final bool reserveLegendSpace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            if (legend != null) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 12, children: legend!),
            ] else if (reserveLegendSpace) ...[
              const SizedBox(height: 12),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 12),
            SizedBox(height: 260, child: child),
          ],
        ),
      ),
    );
  }
}

/// 圖例項目。
class LegendEntry extends StatelessWidget {
  const LegendEntry({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// 空資料訊息。
class EmptyChartMessage extends StatelessWidget {
  const EmptyChartMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Center(
      child: Text(message, style: TextStyle(color: colors.onSurfaceVariant)),
    );
  }
}

/// 統計數據標籤。
class StatChip extends StatelessWidget {
  const StatChip({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
