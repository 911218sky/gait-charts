import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/domain/utils/cohort_benchmark_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metric_status_badge.dart';

/// 指標群組列表。
class MetricGroupList extends StatelessWidget {
  const MetricGroupList({
    required this.title,
    required this.items,
    required this.basis,
    super.key,
  });

  final String title;
  final List<MetricRow> items;
  final CohortBenchmarkCompareBasis basis;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final palette = DashboardBenchmarkCompareColors.of(context);

    if (items.isEmpty) return const SizedBox.shrink();

    Color statusColor(MetricComparisonStatus status) => switch (status) {
      MetricComparisonStatus.belowNormal => palette.lower,
      MetricComparisonStatus.aboveNormal => palette.higher,
      MetricComparisonStatus.normal => palette.inRange,
    };

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.85 : 1),
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: isDark ? 0.9 : 1),
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _MetricRowItem(
                item: item,
                basis: basis,
                title: title,
                statusColor: statusColor,
              );
            },
          ),
        ],
      ),
    );
  }
}


class _MetricRowItem extends StatelessWidget {
  const _MetricRowItem({
    required this.item,
    required this.basis,
    required this.title,
    required this.statusColor,
  });

  final MetricRow item;
  final CohortBenchmarkCompareBasis basis;
  final String title;
  final Color Function(MetricComparisonStatus) statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final c = item.comparison;
    final userV = userValueForBasis(c, basis);
    final benchV = benchmarkValueForBasis(c, basis);
    final status = c.status;
    final pct = percentilePositionForBasis(c, basis);
    final diffPct = diffPctForBasis(c, basis);
    final diffText = diffPct == null
        ? ''
        : ' · 差異=${diffPct.toStringAsFixed(2)}%';
    final bwLabel = betterWorseLabel(
      group: title,
      metricKey: item.key,
      status: status,
    );
    final supportDiff = supportDiffLabelP50(
      group: title,
      metricKey: item.key,
      c: c,
    );
    final supportDiffColor = supportDiffColorP50(
      context: context,
      group: title,
      metricKey: item.key,
      c: c,
    );
    final subtitle =
        '個人${compareBasisLabelShort(basis)}=${userV.toStringAsFixed(3)}（n=${c.userCount}） · 族群${compareBasisLabelShort(basis)}=${benchV.toStringAsFixed(3)}（n=${c.benchmarkCount}）$diffText · P25-P75=${c.benchmarkP25.toStringAsFixed(3)}~${c.benchmarkP75.toStringAsFixed(3)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: statusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MetricStatusBadge(
                      status: status,
                      label: statusLabelShort(status),
                      size: MetricBadgeSize.small,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                if (supportDiff != null || bwLabel != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (supportDiff != null)
                        Text(
                          supportDiff,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: supportDiffColor ?? colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      if (bwLabel != null)
                        MetricPerformanceBadge(
                          label: bwLabel,
                          variant: _performanceVariant(bwLabel),
                          size: MetricBadgeSize.small,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  MetricPerformanceVariant _performanceVariant(String? label) {
    if (label == null) return MetricPerformanceVariant.normal;
    return switch (label) {
      '較佳' => MetricPerformanceVariant.better,
      '較差' => MetricPerformanceVariant.worse,
      '正常' => MetricPerformanceVariant.normal,
      _ => MetricPerformanceVariant.normal,
    };
  }
}
