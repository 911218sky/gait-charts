import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metrics/metric_status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

/// 指標重點卡片：突出顯示重要指標的狀態和數值。
class MetricHighlightCard extends StatelessWidget {
  const MetricHighlightCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    this.performanceLabel,
    this.performanceVariant,
    this.diffLabel,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String unit;
  final MetricComparisonStatus status;
  final String? performanceLabel;
  final MetricPerformanceVariant? performanceVariant;
  final String? diffLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final palette = DashboardBenchmarkCompareColors.of(context);

    final statusColor = switch (status) {
      MetricComparisonStatus.similar => palette.inRange,
      MetricComparisonStatus.worse => palette.lower,
      MetricComparisonStatus.better => colors.tertiary,
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
            mainAxisSize: MainAxisSize.min,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (performanceLabel != null && performanceVariant != null)
                    MetricPerformanceBadge(
                      label: performanceLabel!,
                      variant: performanceVariant!,
                      size: MetricBadgeSize.small,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // 數值顯示
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              if (diffLabel != null) ...[
                const SizedBox(height: 8),
                Text(
                  diffLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
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
}
