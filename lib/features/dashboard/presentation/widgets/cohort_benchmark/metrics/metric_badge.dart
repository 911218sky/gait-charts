import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:google_fonts/google_fonts.dart';

/// Badge 尺寸。
enum MetricBadgeSize { small, medium, large, xlarge }

/// 表現變體：較佳、較差、正常。
enum MetricPerformanceVariant { better, worse, normal }

/// 統一的指標標籤組件。
///
/// 支援兩種模式：
/// - Status 模式：顯示 [MetricComparisonStatus] 狀態（正常/低於/高於）
/// - Performance 模式：顯示表現評價（較佳/較差/正常）
class MetricBadge extends StatelessWidget {
  /// 建立 Status 模式的 Badge。
  const MetricBadge.status({
    required this.label,
    required MetricComparisonStatus this.status,
    this.size = MetricBadgeSize.medium,
    super.key,
  }) : performanceVariant = null;

  /// 建立 Performance 模式的 Badge。
  const MetricBadge.performance({
    required this.label,
    required MetricPerformanceVariant this.performanceVariant,
    this.size = MetricBadgeSize.medium,
    super.key,
  }) : status = null;

  final String label;
  final MetricComparisonStatus? status;
  final MetricPerformanceVariant? performanceVariant;
  final MetricBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final palette = DashboardBenchmarkCompareColors.of(context);

    final (bgColor, borderColor, textColor, icon) = status != null
        ? _getStatusStyle(status!, colors, palette)
        : _getPerformanceStyle(performanceVariant!, colors, palette);

    final iconSize = switch (size) {
      MetricBadgeSize.small => 12.0,
      MetricBadgeSize.medium => 16.0,
      MetricBadgeSize.large => 18.0,
      MetricBadgeSize.xlarge => 20.0,
    };

    final fontSize = switch (size) {
      MetricBadgeSize.small => 11.0,
      MetricBadgeSize.medium => 13.0,
      MetricBadgeSize.large => 14.0,
      MetricBadgeSize.xlarge => 15.0,
    };

    final padding = switch (size) {
      MetricBadgeSize.small =>
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      MetricBadgeSize.medium =>
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      MetricBadgeSize.large =>
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      MetricBadgeSize.xlarge =>
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    };

    final borderRadius = switch (size) {
      MetricBadgeSize.small => 6.0,
      MetricBadgeSize.medium => 8.0,
      MetricBadgeSize.large => 8.0,
      MetricBadgeSize.xlarge => 10.0,
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
      MetricComparisonStatus.similar => (
          palette.inRange.withValues(alpha: 0.15),
          palette.inRange.withValues(alpha: 0.4),
          palette.inRange,
          Icons.check_circle_rounded,
        ),
      MetricComparisonStatus.worse => (
          palette.lower.withValues(alpha: 0.15),
          palette.lower.withValues(alpha: 0.4),
          palette.lower,
          Icons.trending_down_rounded,
        ),
      MetricComparisonStatus.better => (
          colors.tertiary.withValues(alpha: 0.15),
          colors.tertiary.withValues(alpha: 0.4),
          colors.tertiary,
          Icons.trending_up_rounded,
        ),
    };
  }

  (Color, Color, Color, IconData) _getPerformanceStyle(
    MetricPerformanceVariant variant,
    ColorScheme colors,
    DashboardBenchmarkCompareColors palette,
  ) {
    return switch (variant) {
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
      // 正常狀態使用 inRange 顏色，與 status 模式一致
      MetricPerformanceVariant.normal => (
          palette.inRange.withValues(alpha: 0.15),
          palette.inRange.withValues(alpha: 0.4),
          palette.inRange,
          Icons.remove_rounded,
        ),
    };
  }
}
