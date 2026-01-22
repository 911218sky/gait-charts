import 'package:flutter/material.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metrics/metric_badge.dart';

// 向後相容性：重新導出統一的 MetricBadge 組件
export 'metric_badge.dart';

/// 舊版尺寸 enum，映射到新的 [MetricBadgeSize]。
@Deprecated('使用 MetricBadgeSize 代替')
typedef MetricStatusBadgeSize = MetricBadgeSize;

/// 指標狀態標籤：顯示好壞狀態的視覺化標籤。
///
/// 建議改用 [MetricBadge.status]。
class MetricStatusBadge extends StatelessWidget {
  const MetricStatusBadge({
    required this.status,
    required this.label,
    this.size = MetricBadgeSize.medium,
    super.key,
  });

  final MetricComparisonStatus status;
  final String label;
  final MetricBadgeSize size;

  @override
  Widget build(BuildContext context) {
    return MetricBadge.status(
      status: status,
      label: label,
      size: size,
    );
  }
}

/// 指標表現標籤：顯示「較佳」「較差」「正常」等評價。
///
/// 建議改用 [MetricBadge.performance]。
class MetricPerformanceBadge extends StatelessWidget {
  const MetricPerformanceBadge({
    required this.label,
    required this.variant,
    this.size = MetricBadgeSize.medium,
    super.key,
  });

  final String label;
  final MetricPerformanceVariant variant;
  final MetricBadgeSize size;

  @override
  Widget build(BuildContext context) {
    return MetricBadge.performance(
      label: label,
      performanceVariant: variant,
      size: size,
    );
  }
}
