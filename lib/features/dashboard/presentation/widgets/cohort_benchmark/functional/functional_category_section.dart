import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/domain/utils/cohort_benchmark_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/shared/shared.dart';
import 'package:google_fonts/google_fonts.dart';

/// 功能類別區塊。
///
/// 顯示單一功能類別（體能、平衡、肌耐力）的所有指標。
/// 包含標題列和指標列表，每個指標以 [FunctionalScoreBar] 呈現。
class FunctionalCategorySection extends StatelessWidget {
  const FunctionalCategorySection({
    required this.title,
    required this.icon,
    required this.description,
    required this.metrics,
    required this.order,
    required this.labels,
    super.key,
  });

  final String title;
  final IconData icon;
  final String description;
  final Map<String, FunctionalMetric> metrics;
  final List<String> order;
  final Map<String, String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final items = buildFunctionalMetricItems(
      metrics,
      order: order,
      labelMap: labels,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF111111) : colors.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 24, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // 圖例說明
                const _DetailLegend(),
              ],
            ),
          ),
          // Metrics List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items.map((item) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: item != items.last ? 16 : 0,
                  ),
                  child: FunctionalScoreBar(
                    label: item.label,
                    metric: item.metric,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 詳細頁面圖例。
class _DetailLegend extends StatelessWidget {
  const _DetailLegend();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        // 標記說明
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 個人
            _LegendItem(
              marker: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              label: '個人',
              color: colors.primary,
            ),
            const SizedBox(width: 12),
            // 族群
            _LegendItem(
              marker: Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              label: '族群',
              color: Colors.amber,
            ),
            const SizedBox(width: 12),
            // 參考值
            _LegendItem(
              marker: Container(
                width: 2,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              label: '參考',
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
        // 分隔線
        Container(
          width: 1,
          height: 16,
          color: colors.outlineVariant,
        ),
        // 狀態說明
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusLegendItem(
              icon: Icons.star_rounded,
              label: '優',
              color: colors.tertiary,
            ),
            const SizedBox(width: 10),
            _StatusLegendItem(
              icon: Icons.check_circle_rounded,
              label: '正常',
              color: colors.primary,
            ),
            const SizedBox(width: 10),
            _StatusLegendItem(
              icon: Icons.warning_rounded,
              label: '待加強',
              color: colors.error.withValues(alpha: 0.85),
            ),
          ],
        ),
      ],
    );
  }
}

/// 狀態圖例項目。
class _StatusLegendItem extends StatelessWidget {
  const _StatusLegendItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.marker,
    required this.label,
    required this.color,
  });

  final Widget marker;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 12, height: 12, child: Center(child: marker)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 功能性指標分數條圖。
///
/// 顯示線性刻度條，參考值在中間，使用者和族群位置用標記顯示。
/// 使用 [LinearScaleBar] 和 [ScaleBarLegend] 共用元件。
class FunctionalScoreBar extends StatelessWidget {
  const FunctionalScoreBar({
    required this.label,
    required this.metric,
    super.key,
  });

  final String label;
  final FunctionalMetric metric;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final palette = DashboardBenchmarkCompareColors.of(context);

    final diffLabel = functionalDiffLabel(metric);
    final status = functionalStatus(metric);

    // 根據 higherIsBetter 決定顏色
    final statusColor = switch (status) {
      MetricComparisonStatus.similar => palette.inRange,
      MetricComparisonStatus.worse => palette.lower,
      MetricComparisonStatus.better => colors.tertiary,
    };

    final statusIcon = switch (status) {
      MetricComparisonStatus.similar => Icons.check_circle_rounded,
      MetricComparisonStatus.worse => Icons.warning_rounded,
      MetricComparisonStatus.better => Icons.star_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Row(
            children: [
              // 狀態圖示
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, size: 16, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              // 差異標籤
              if (diffLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    diffLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 線性刻度條
          LinearScaleBar(
            metric: metric,
            statusColor: statusColor,
          ),

          const SizedBox(height: 14),

          // 數值摘要列
          _ValueSummaryRow(metric: metric, statusColor: statusColor),
        ],
      ),
    );
  }
}

/// 數值摘要列。
class _ValueSummaryRow extends StatelessWidget {
  const _ValueSummaryRow({
    required this.metric,
    required this.statusColor,
  });

  final FunctionalMetric metric;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Row(
      children: [
        // 個人數值（重點顯示）
        Expanded(
          child: _ValueChip(
            label: '個人',
            value: '${metric.userValue.toStringAsFixed(2)}s',
            color: statusColor,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 8),
        // 族群數值
        if (metric.cohortValue != null) ...[
          Expanded(
            child: _ValueChip(
              label: '族群',
              value: '${metric.cohortValue!.toStringAsFixed(2)}s',
              color: Colors.amber,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 8),
        ],
        // 參考值
        Expanded(
          child: _ValueChip(
            label: '參考',
            value: '${metric.referenceValue.toStringAsFixed(2)}s',
            color: colors.onSurfaceVariant,
            isPrimary: false,
          ),
        ),
      ],
    );
  }
}

/// 數值標籤。
class _ValueChip extends StatelessWidget {
  const _ValueChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isPrimary,
  });

  final String label;
  final String value;
  final Color color;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary
            ? color.withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF1A1A1A) : colors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(8),
        border: isPrimary
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isPrimary ? 16 : 14,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
