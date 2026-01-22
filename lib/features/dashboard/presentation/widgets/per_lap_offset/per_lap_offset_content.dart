import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/chart_config_provider.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/per_lap_offset/per_lap_offset_overview_chart.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/per_lap_offset/widgets/widgets.dart';

/// 組裝圈數選擇與詳細圖表的主要內容。
class PerLapOffsetContent extends ConsumerWidget {
  const PerLapOffsetContent({
    required this.response,
    required this.showSamples,
    required this.sampleLimit,
    required this.onToggleSamples,
    required this.onChangeSampleLimit,
    required this.detailSectionKey,
    super.key,
  });

  final PerLapOffsetResponse response;
  final bool showSamples;
  final int? sampleLimit;
  final ValueChanged<bool> onToggleSamples;
  final ValueChanged<int?> onChangeSampleLimit;
  final Key detailSectionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laps = response.laps;
    if (laps.isEmpty) {
      return const SizedBox.shrink();
    }
    final chartConfig = ref.watch(chartConfigProvider);

    final hasAnglePanorama = laps.any(
      (lap) =>
          lap.thetaDegrees.isNotEmpty &&
          lap.thetaDegrees.length == lap.timeSeconds.length,
    );
    final selectedLapIndex = ref.watch(perLapOffsetSelectedLapProvider);
    final selectedLap = laps.firstWhere(
      (lap) => lap.lapIndex == selectedLapIndex,
      orElse: () => laps.first,
    );
    final accent = DashboardAccentColors.of(context);
    final colors = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PerLapOffsetOverviewChart(
          laps: laps,
          maxPoints: chartConfig.perLapOverviewMaxPoints,
        ),
        if (hasAnglePanorama) ...[
          const SizedBox(height: 24),
          PerLapAngleOverviewChart(
            laps: laps,
            maxPoints: chartConfig.perLapOverviewMaxPoints,
          ),
        ],
        const SizedBox(height: 24),
        PerLapLapSelector(laps: laps),
        const SizedBox(height: 12),
        _SampleControls(
          showSamples: showSamples,
          sampleLimit: sampleLimit,
          onToggleSamples: onToggleSamples,
          onChangeSampleLimit: onChangeSampleLimit,
          colors: colors,
        ),
        const SizedBox(height: 8),
        Container(
          key: detailSectionKey,
          child: PerLapCard(
            lap: selectedLap,
            accent: accent,
            showSamples: showSamples,
            sampleLimit: sampleLimit,
            seriesMaxPoints: chartConfig.perLapSeriesMaxPoints,
            thetaMaxPoints: chartConfig.perLapThetaMaxPoints,
          ),
        ),
      ],
    );
  }
}

/// 取樣點控制列。
class _SampleControls extends StatelessWidget {
  const _SampleControls({
    required this.showSamples,
    required this.sampleLimit,
    required this.onToggleSamples,
    required this.onChangeSampleLimit,
    required this.colors,
  });

  final bool showSamples;
  final int? sampleLimit;
  final ValueChanged<bool> onToggleSamples;
  final ValueChanged<int?> onChangeSampleLimit;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '顯示取樣點',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Switch.adaptive(value: showSamples, onChanged: onToggleSamples),
        const SizedBox(width: 24),
        Text(
          '最多點數',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: showSamples ? 0.8 : 0.3),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: AppSelect<int?>(
            value: sampleLimit,
            items: const [60, 120, 240, null],
            itemLabelBuilder: (item) => item?.toString() ?? '不限制',
            enabled: showSamples,
            onChanged: showSamples ? onChangeSampleLimit : null,
            menuWidth: const BoxConstraints(minWidth: 100, maxWidth: 140),
          ),
        ),
      ],
    );
  }
}
