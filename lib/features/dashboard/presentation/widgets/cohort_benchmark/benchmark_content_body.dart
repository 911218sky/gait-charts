import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/domain/utils/cohort_benchmark_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/benchmark_radar.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metric_group_list.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metric_highlight_card.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metric_status_badge.dart';

/// 族群基準比對的內容主體。
class BenchmarkContentBody extends StatelessWidget {
  const BenchmarkContentBody({
    required this.tabId,
    required this.data,
    required this.basis,
    required this.basisLabel,
    required this.isWide,
    super.key,
  });

  final String tabId;
  final CohortBenchmarkCompareResponse data;
  final CohortBenchmarkCompareBasis basis;
  final String basisLabel;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    switch (tabId) {
      case 'overview':
        return _buildOverview(context);
      case 'lap_time':
        return _buildDetailSection(
          context,
          title: 'Lap Time',
          map: data.lapTime,
          order: lapTimeOrder,
          labels: lapTimeLabels,
        );
      case 'gait':
        return _buildDetailSection(
          context,
          title: 'Gait',
          map: data.gait,
          order: gaitOrder,
          labels: gaitLabels,
        );
      case 'speed_distance':
        return _buildDetailSection(
          context,
          title: 'Speed & Distance',
          map: data.speedDistance,
          order: speedOrder,
          labels: speedLabels,
        );
      case 'turn':
        return _buildDetailSection(
          context,
          title: 'Turn',
          map: data.turn,
          order: turnOrder,
          labels: turnLabels,
        );
      default:
        return const SizedBox.shrink();
    }
  }


  Widget _buildOverview(BuildContext context) {
    final lapEntries = buildRadarEntries(
      context,
      'lap_time',
      data.lapTime,
      lapTimeOrder,
      lapTimeLabels,
      basis,
    );
    final gaitEntries = buildRadarEntries(
      context,
      'gait',
      data.gait,
      gaitOrder,
      gaitLabels,
      basis,
    );
    final speedEntries = buildRadarEntries(
      context,
      'speed_distance',
      data.speedDistance,
      speedOrder,
      speedLabels,
      basis,
    );

    final highlightMetrics = _buildHighlightMetrics(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (highlightMetrics.isNotEmpty) ...[
          Text(
            '重點指標',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800
                  ? 4
                  : constraints.maxWidth > 600
                      ? 3
                      : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: highlightMetrics.length,
                itemBuilder: (context, index) => highlightMetrics[index],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
        if (lapEntries.isNotEmpty)
          _OverviewCard(
            title: 'Lap Time',
            entries: lapEntries,
            basisLabel: basisLabel,
            basis: basis,
          ),
        const SizedBox(height: 24),
        if (gaitEntries.isNotEmpty)
          _OverviewCard(
            title: 'Gait',
            entries: gaitEntries,
            basisLabel: basisLabel,
            basis: basis,
          ),
        const SizedBox(height: 24),
        if (speedEntries.isNotEmpty)
          _OverviewCard(
            title: 'Speed',
            entries: speedEntries,
            basisLabel: basisLabel,
            basis: basis,
          ),
      ],
    );
  }

  List<Widget> _buildHighlightMetrics(BuildContext context) {
    final highlights = <Widget>[];

    // 速度 (speed_mps)
    final speedComp = data.speedDistance['speed_mps'];
    if (speedComp != null) {
      final userV = userValueForBasis(speedComp, basis);
      final pct = percentilePositionForBasis(speedComp, basis);
      final perfLabel = betterWorseLabel(
        group: 'speed_distance',
        metricKey: 'speed_mps',
        status: speedComp.status,
      );
      final perfVariant = _performanceVariant(perfLabel);
      final supportDiff = supportDiffLabelP50(
        group: 'speed_distance',
        metricKey: 'speed_mps',
        c: speedComp,
      );

      highlights.add(
        MetricHighlightCard(
          label: '速度',
          value: userV.toStringAsFixed(2),
          unit: 'm/s',
          status: speedComp.status,
          performanceLabel: perfLabel,
          performanceVariant: perfVariant,
          percentile: pct,
          subtitle: supportDiff,
        ),
      );
    }

    // 單圈總時間 (dur_total)
    final durTotalComp = data.lapTime['dur_total'];
    if (durTotalComp != null) {
      final userV = userValueForBasis(durTotalComp, basis);
      final pct = percentilePositionForBasis(durTotalComp, basis);
      final perfLabel = betterWorseLabel(
        group: 'lap_time',
        metricKey: 'dur_total',
        status: durTotalComp.status,
      );
      final perfVariant = _performanceVariant(perfLabel);
      final supportDiff = supportDiffLabelP50(
        group: 'lap_time',
        metricKey: 'dur_total',
        c: durTotalComp,
      );

      highlights.add(
        MetricHighlightCard(
          label: '單圈總時間',
          value: userV.toStringAsFixed(2),
          unit: 's',
          status: durTotalComp.status,
          performanceLabel: perfLabel,
          performanceVariant: perfVariant,
          percentile: pct,
          subtitle: supportDiff,
        ),
      );
    }

    // 步頻 (spm)
    final spmComp = data.gait['spm'];
    if (spmComp != null) {
      final userV = userValueForBasis(spmComp, basis);
      final pct = percentilePositionForBasis(spmComp, basis);

      highlights.add(
        MetricHighlightCard(
          label: '步頻',
          value: userV.toStringAsFixed(1),
          unit: 'steps/min',
          status: spmComp.status,
          percentile: pct,
        ),
      );
    }

    // 平均步長 (mean_step_len)
    final stepLenComp = data.gait['mean_step_len'];
    if (stepLenComp != null) {
      final userV = userValueForBasis(stepLenComp, basis);
      final pct = percentilePositionForBasis(stepLenComp, basis);

      highlights.add(
        MetricHighlightCard(
          label: '平均步長',
          value: userV.toStringAsFixed(3),
          unit: 'm',
          status: stepLenComp.status,
          percentile: pct,
        ),
      );
    }

    return highlights;
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


  Widget _buildDetailSection(
    BuildContext context, {
    required String title,
    required Map<String, MetricComparison> map,
    required List<String> order,
    required Map<String, String> labels,
  }) {
    final entries = buildRadarEntries(context, title, map, order, labels, basis);
    final items = buildMetricItems(map, order: order, labelMap: labels);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entries.isNotEmpty)
          BenchmarkRadar(
            title: title,
            subtitle:
                '雷達圖：使用者${compareBasisLabelShort(basis)}在族群中的百分位 · 數值顯示：$basisLabel',
            entries: entries,
            height: 320,
          ),
        const SizedBox(height: 32),
        MetricGroupList(title: '$title Metrics', items: items, basis: basis),
      ],
    );
  }
}

/// 總覽卡片。
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.entries,
    required this.basisLabel,
    required this.basis,
  });

  final String title;
  final List<BenchmarkRadarEntry> entries;
  final String basisLabel;
  final CohortBenchmarkCompareBasis basis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: context.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BenchmarkRadar(
            title: title,
            subtitle:
                '雷達圖：使用者${compareBasisLabelShort(basis)}在族群中的百分位 · 數值顯示：$basisLabel',
            entries: entries,
            height: 300,
          ),
        ],
      ),
    );
  }
}
