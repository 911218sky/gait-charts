import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/domain/utils/cohort_benchmark_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metrics/metric_status_badge.dart';

/// 指標群組列表（簡化版，適配新 API）。
class MetricGroupList extends StatelessWidget {
  const MetricGroupList({
    required this.title,
    required this.items,
    super.key,
  });

  final String title;
  final List<MetricRow> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final palette = DashboardBenchmarkCompareColors.of(context);

    if (items.isEmpty) return const SizedBox.shrink();

    Color statusColor(MetricComparisonStatus status) => switch (status) {
      MetricComparisonStatus.worse => palette.lower,
      MetricComparisonStatus.better => colors.tertiary,
      MetricComparisonStatus.similar => palette.inRange,
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
    required this.statusColor,
  });

  final MetricRow item;
  final Color Function(MetricComparisonStatus) statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final c = item.comparison;
    final status = c.status;
    final diffLabelText = diffLabel(c);
    final diffLabelColor = diffColor(context, c);

    // 簡化的 subtitle：個人值 vs 族群值
    final subtitle =
        '個人=${c.userValue.toStringAsFixed(3)} · 族群=${c.cohortValue.toStringAsFixed(3)}';

    // 表現標籤
    final perfLabel = c.isBetter ? '較佳' : (c.status == MetricComparisonStatus.worse ? '較差' : '正常');
    final perfVariant = c.isBetter
        ? MetricPerformanceVariant.better
        : (c.status == MetricComparisonStatus.worse
            ? MetricPerformanceVariant.worse
            : MetricPerformanceVariant.normal);

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
                if (diffLabelText != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        diffLabelText,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: diffLabelColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      MetricPerformanceBadge(
                        label: perfLabel,
                        variant: perfVariant,
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
}
