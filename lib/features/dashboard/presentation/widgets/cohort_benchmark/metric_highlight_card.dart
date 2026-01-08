import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metric_status_badge.dart';

/// 指標重點卡片：突出顯示重要指標的狀態和數值。
class MetricHighlightCard extends StatelessWidget {
  const MetricHighlightCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    this.performanceLabel,
    this.performanceVariant,
    this.percentile,
    this.subtitle,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String unit;
  final MetricComparisonStatus status;
  final String? performanceLabel;
  final MetricPerformanceVariant? performanceVariant;
  final double? percentile;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final palette = DashboardBenchmarkCompareColors.of(context);

    final statusColor = switch (status) {
      MetricComparisonStatus.normal => palette.inRange,
      MetricComparisonStatus.belowNormal => palette.lower,
      MetricComparisonStatus.aboveNormal => palette.higher,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: 標籤 + 狀態標籤
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  MetricStatusBadge(
                    status: status,
                    label: _statusLabel(status),
                    size: MetricStatusBadgeSize.small,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 數值顯示
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    unit,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (percentile != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '百分位：${percentile!.toStringAsFixed(1)}%',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (performanceLabel != null && performanceVariant != null) ...[
                const SizedBox(height: 10),
                MetricPerformanceBadge(
                  label: performanceLabel!,
                  variant: performanceVariant!,
                  size: MetricStatusBadgeSize.small,
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(MetricComparisonStatus status) => switch (status) {
        MetricComparisonStatus.normal => '正常範圍',
        MetricComparisonStatus.belowNormal => '低於範圍',
        MetricComparisonStatus.aboveNormal => '高於範圍',
      };
}
