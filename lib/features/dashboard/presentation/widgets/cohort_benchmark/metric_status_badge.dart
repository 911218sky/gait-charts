import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:google_fonts/google_fonts.dart';

/// 指標狀態標籤：顯示好壞狀態的視覺化標籤。
class MetricStatusBadge extends StatelessWidget {
  const MetricStatusBadge({
    required this.status,
    required this.label,
    this.size = MetricStatusBadgeSize.medium,
    super.key,
  });

  final MetricComparisonStatus status;
  final String label;
  final MetricStatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final palette = DashboardBenchmarkCompareColors.of(context);

    final (bgColor, borderColor, textColor, icon) = _getStatusStyle(
      status,
      colors,
      palette,
    );

    final iconSize = switch (size) {
      MetricStatusBadgeSize.small => 12.0,
      MetricStatusBadgeSize.medium => 16.0,
      MetricStatusBadgeSize.large => 18.0,
      MetricStatusBadgeSize.xlarge => 20.0,
    };

    final fontSize = switch (size) {
      MetricStatusBadgeSize.small => 11.0,
      MetricStatusBadgeSize.medium => 13.0,
      MetricStatusBadgeSize.large => 14.0,
      MetricStatusBadgeSize.xlarge => 15.0,
    };

    final padding = switch (size) {
      MetricStatusBadgeSize.small =>
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      MetricStatusBadgeSize.medium =>
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      MetricStatusBadgeSize.large =>
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      MetricStatusBadgeSize.xlarge =>
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    };

    final borderRadius = switch (size) {
      MetricStatusBadgeSize.small => 6.0,
      MetricStatusBadgeSize.medium => 8.0,
      MetricStatusBadgeSize.large => 8.0,
      MetricStatusBadgeSize.xlarge => 10.0,
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, Color, IconData) _getStatusStyle(
    MetricComparisonStatus status,
    ColorScheme colors,
    DashboardBenchmarkCompareColors palette,
  ) {
    return switch (status) {
      MetricComparisonStatus.normal => (
          palette.inRange.withValues(alpha: 0.15),
          palette.inRange.withValues(alpha: 0.4),
          palette.inRange,
          Icons.check_circle_rounded,
        ),
      MetricComparisonStatus.belowNormal => (
          palette.lower.withValues(alpha: 0.15),
          palette.lower.withValues(alpha: 0.4),
          palette.lower,
          Icons.arrow_downward_rounded,
        ),
      MetricComparisonStatus.aboveNormal => (
          palette.higher.withValues(alpha: 0.15),
          palette.higher.withValues(alpha: 0.4),
          palette.higher,
          Icons.arrow_upward_rounded,
        ),
    };
  }
}

enum MetricStatusBadgeSize { small, medium, large, xlarge }

/// 指標表現標籤：顯示「較佳」「較差」「正常」等評價。
class MetricPerformanceBadge extends StatelessWidget {
  const MetricPerformanceBadge({
    required this.label,
    required this.variant,
    this.size = MetricStatusBadgeSize.medium,
    super.key,
  });

  final String label;
  final MetricPerformanceVariant variant;
  final MetricStatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    final (bgColor, borderColor, textColor, icon) = switch (variant) {
      MetricPerformanceVariant.better => (
          colors.tertiary.withValues(alpha: 0.15),
          colors.tertiary.withValues(alpha: 0.4),
          colors.tertiary,
          Icons.trending_up_rounded,
        ),
      MetricPerformanceVariant.worse => (
          colors.error.withValues(alpha: 0.15),
          colors.error.withValues(alpha: 0.4),
          colors.error,
          Icons.trending_down_rounded,
        ),
      MetricPerformanceVariant.normal => (
          colors.outline.withValues(alpha: 0.15),
          colors.outline.withValues(alpha: 0.4),
          colors.outline,
          Icons.remove_rounded,
        ),
    };

    final iconSize = switch (size) {
      MetricStatusBadgeSize.small => 12.0,
      MetricStatusBadgeSize.medium => 16.0,
      MetricStatusBadgeSize.large => 18.0,
      MetricStatusBadgeSize.xlarge => 20.0,
    };

    final fontSize = switch (size) {
      MetricStatusBadgeSize.small => 11.0,
      MetricStatusBadgeSize.medium => 13.0,
      MetricStatusBadgeSize.large => 14.0,
      MetricStatusBadgeSize.xlarge => 15.0,
    };

    final padding = switch (size) {
      MetricStatusBadgeSize.small =>
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      MetricStatusBadgeSize.medium =>
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      MetricStatusBadgeSize.large =>
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      MetricStatusBadgeSize.xlarge =>
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    };

    final borderRadius = switch (size) {
      MetricStatusBadgeSize.small => 6.0,
      MetricStatusBadgeSize.medium => 8.0,
      MetricStatusBadgeSize.large => 8.0,
      MetricStatusBadgeSize.xlarge => 10.0,
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum MetricPerformanceVariant { better, worse, normal }
