import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/domain/utils/cohort_benchmark_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/benchmark_radar.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/functional/functional.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/metrics/metrics.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/shared/shared.dart';

/// 族群基準比對的內容主體（簡化版，適配新 API）。
///
/// 根據 tabId 顯示不同的內容區塊，包含總覽、各類指標詳情和功能評估。
class BenchmarkContentBody extends StatelessWidget {
  const BenchmarkContentBody({
    required this.tabId,
    required this.data,
    required this.isWide,
    super.key,
  });

  final String tabId;
  final CohortBenchmarkCompareResponse data;
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
      case 'functional':
        return _buildFunctionalSection(context);
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
    );
    final gaitEntries = buildRadarEntries(
      context,
      'gait',
      data.gait,
      gaitOrder,
      gaitLabels,
    );
    final speedEntries = buildRadarEntries(
      context,
      'speed_distance',
      data.speedDistance,
      speedOrder,
      speedLabels,
    );

    final highlightMetrics = _buildHighlightMetrics(context);
    final functional = data.functional;

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
        // 功能評估摘要
        if (functional != null && functional.hasData) ...[
          FunctionalOverviewCard(
            functional: functional,
            cohortName: data.cohortName,
          ),
          const SizedBox(height: 24),
        ],
        if (lapEntries.isNotEmpty)
          OverviewCard(title: 'Lap Time', entries: lapEntries),
        const SizedBox(height: 24),
        if (gaitEntries.isNotEmpty)
          OverviewCard(title: 'Gait', entries: gaitEntries),
        const SizedBox(height: 24),
        if (speedEntries.isNotEmpty)
          OverviewCard(title: '距離', entries: speedEntries),
      ],
    );
  }

  List<Widget> _buildHighlightMetrics(BuildContext context) {
    final highlights = <Widget>[];

    // 速度 (speed_mps)
    final speedComp = data.speedDistance['speed_mps'];
    if (speedComp != null) {
      final perfLabel = speedComp.isBetter
          ? '較佳'
          : (speedComp.status == MetricComparisonStatus.worse ? '較差' : '正常');
      final perfVariant = _performanceVariant(perfLabel);

      highlights.add(
        MetricHighlightCard(
          label: '速度',
          value: speedComp.userValue.toStringAsFixed(2),
          unit: 'm/s',
          status: speedComp.status,
          performanceLabel: perfLabel,
          performanceVariant: perfVariant,
          diffLabel: diffLabel(speedComp),
        ),
      );
    }

    // 單圈總時間 (dur_total)
    final durTotalComp = data.lapTime['dur_total'];
    if (durTotalComp != null) {
      final perfLabel = durTotalComp.isBetter
          ? '較佳'
          : (durTotalComp.status == MetricComparisonStatus.worse
              ? '較差'
              : '正常');
      final perfVariant = _performanceVariant(perfLabel);

      highlights.add(
        MetricHighlightCard(
          label: '單圈總時間',
          value: durTotalComp.userValue.toStringAsFixed(2),
          unit: 's',
          status: durTotalComp.status,
          performanceLabel: perfLabel,
          performanceVariant: perfVariant,
          diffLabel: diffLabel(durTotalComp),
        ),
      );
    }

    // 步頻 (spm)
    final spmComp = data.gait['spm'];
    if (spmComp != null) {
      highlights.add(
        MetricHighlightCard(
          label: '步頻',
          value: spmComp.userValue.toStringAsFixed(1),
          unit: 'steps/min',
          status: spmComp.status,
          diffLabel: diffLabel(spmComp),
        ),
      );
    }

    // 平均步長 (mean_step_len)
    final stepLenComp = data.gait['mean_step_len'];
    if (stepLenComp != null) {
      highlights.add(
        MetricHighlightCard(
          label: '平均步長',
          value: stepLenComp.userValue.toStringAsFixed(3),
          unit: 'm',
          status: stepLenComp.status,
          diffLabel: diffLabel(stepLenComp),
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
    final entries = buildRadarEntries(context, title, map, order, labels);
    final items = buildMetricItems(map, order: order, labelMap: labels);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entries.isNotEmpty)
          BenchmarkRadar(
            title: title,
            subtitle: '雷達圖：使用者相對族群的表現（100% = 族群基準）',
            entries: entries,
            height: 320,
          ),
        const SizedBox(height: 32),
        MetricGroupList(title: '$title Metrics', items: items),
      ],
    );
  }

  Widget _buildFunctionalSection(BuildContext context) {
    final functional = data.functional;
    if (functional == null || !functional.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Text(
            '此 Session 沒有功能評估資料',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return FunctionalAssessmentCard(functional: functional);
  }
}
