import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/chart_config_provider.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/chart_dots.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/per_lap_offset/per_lap_offset_overview_chart.dart';

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
        Row(
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
        ),
        const SizedBox(height: 8),
        Container(
          key: detailSectionKey,
          child: _PerLapCard(
            lap: selectedLap,
            accent: accent,
            showSamples: showSamples,
            sampleLimit: sampleLimit,
            seriesMaxPoints: chartConfig.perLapSeriesMaxPoints,
            psdMaxPoints: chartConfig.perLapPsdMaxPoints,
            thetaMaxPoints: chartConfig.perLapThetaMaxPoints,
          ),
        ),
      ],
    );
  }
}

class PerLapLapSelector extends ConsumerWidget {
  const PerLapLapSelector({required this.laps, super.key});

  final List<PerLapOffsetLap> laps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLap = ref.watch(perLapOffsetSelectedLapProvider);
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final textTheme = context.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '選擇要檢視的圈數',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '共 ${laps.length} 圈',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: laps.map((lap) {
                final isSelected = lap.lapIndex == selectedLap;
                final lapDuration = lap.lapDurationSeconds;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => ref
                        .read(perLapOffsetSelectedLapProvider.notifier)
                        .select(lap.lapIndex),
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? Colors.white : colors.primary)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? null
                            : Border.all(color: colors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                'Lap ${lap.lapIndex}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? (isDark ? Colors.black : Colors.white)
                                      : colors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lapDuration > 0
                                ? '${lapDuration.toStringAsFixed(1)} s'
                                : '--',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? (isDark ? Colors.black54 : Colors.white.withValues(alpha: 0.7))
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerLapCard extends StatelessWidget {
  const _PerLapCard({
    required this.lap,
    required this.accent,
    required this.showSamples,
    required this.sampleLimit,
    required this.seriesMaxPoints,
    required this.psdMaxPoints,
    required this.thetaMaxPoints,
  });

  final PerLapOffsetLap lap;
  final DashboardAccentColors accent;
  final bool showSamples;
  final int? sampleLimit;
  final int seriesMaxPoints;
  final int psdMaxPoints;
  final int thetaMaxPoints;

  @override
  Widget build(BuildContext context) {
    final peakFreq = lap.fft.peakFrequencyOrNull;
    final peakDb = lap.fft.peakDbOrNull;
    final lapDuration = lap.lapDurationSeconds;
    final walkDuration = lap.walkDurationSeconds;
    final textTheme = context.textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lap ${lap.lapIndex.toString().padLeft(2, '0')}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(
                  label: '圈長',
                  value: lapDuration > 0
                      ? '${lapDuration.toStringAsFixed(1)} s'
                      : '--',
                  color: accent.success,
                ),
                _StatChip(
                  label: '走路區段',
                  value: walkDuration > 0
                      ? '${walkDuration.toStringAsFixed(1)} s'
                      : '--',
                  color: accent.warning,
                ),
                _StatChip(
                  label: '峰值頻率',
                  value: peakFreq != null
                      ? '${peakFreq.toStringAsFixed(2)} Hz'
                      : '--',
                  color: accent.danger,
                ),
                _StatChip(
                  label: '峰值功率',
                  value: peakDb != null
                      ? '${peakDb.toStringAsFixed(1)} dB'
                      : '--',
                  color: const Color(0xFFFFB347),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1500) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LatSeriesChart(
                          lap: lap,
                          showSamples: showSamples,
                          sampleLimit: sampleLimit,
                          maxPoints: seriesMaxPoints,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _LatPsdChart(
                          lap: lap,
                          showSamples: showSamples,
                          sampleLimit: sampleLimit,
                          maxPoints: psdMaxPoints,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ThetaChart(
                          lap: lap,
                          showSamples: showSamples,
                          sampleLimit: sampleLimit,
                          maxPoints: thetaMaxPoints,
                        ),
                      ),
                    ],
                  );
                }
                if (constraints.maxWidth >= 1100) {
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _LatSeriesChart(
                              lap: lap,
                              showSamples: showSamples,
                              sampleLimit: sampleLimit,
                              maxPoints: seriesMaxPoints,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _LatPsdChart(
                              lap: lap,
                              showSamples: showSamples,
                              sampleLimit: sampleLimit,
                              maxPoints: psdMaxPoints,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ThetaChart(
                        lap: lap,
                        showSamples: showSamples,
                        sampleLimit: sampleLimit,
                        maxPoints: thetaMaxPoints,
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _LatSeriesChart(
                      lap: lap,
                      showSamples: showSamples,
                      sampleLimit: sampleLimit,
                      maxPoints: seriesMaxPoints,
                    ),
                    const SizedBox(height: 16),
                    _LatPsdChart(
                      lap: lap,
                      showSamples: showSamples,
                      sampleLimit: sampleLimit,
                      maxPoints: psdMaxPoints,
                    ),
                    const SizedBox(height: 16),
                    _ThetaChart(
                      lap: lap,
                      showSamples: showSamples,
                      sampleLimit: sampleLimit,
                      maxPoints: thetaMaxPoints,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LatSeriesChart extends StatelessWidget {
  const _LatSeriesChart({
    required this.lap,
    required this.showSamples,
    required this.sampleLimit,
    required this.maxPoints,
  });

  final PerLapOffsetLap lap;
  final bool showSamples;
  final int? sampleLimit;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    final time = lap.timeSeconds;
    if (time.isEmpty || lap.latSmooth.isEmpty) {
      return const _LapChartCard(
        title: 'lat(t)',
        subtitle: '原始與平滑後 lateral offset',
        child: _EmptyChartMessage('缺少 lateral offset 資料'),
      );
    }

    final unlimitSamples = showSamples && sampleLimit == null;
    final rawSpots = _buildSpots(
      time,
      lap.latRaw,
      maxPoints: unlimitSamples ? time.length : maxPoints,
    );
    final smoothSpots = _buildSpots(
      time,
      lap.latSmooth,
      maxPoints: unlimitSamples ? time.length : maxPoints,
    );
    final yRange = _computeRange([...lap.latRaw, ...lap.latSmooth]);
    final padding = yRange.delta == 0 ? 0.5 : yRange.delta * 0.1;
    final minY = yRange.min - padding;
    final maxY = yRange.max + padding;

    final annotations = _buildRegionAnnotations(
      time,
      lap,
      turnColor: const Color(0xFF95B7FF).withValues(alpha: 0.24),
    );
    final rawSampleSpots = showSamples
        ? _limitFlSpots(rawSpots, sampleLimit)
        : null;
    final smoothSampleSpots = showSamples
        ? _limitFlSpots(smoothSpots, sampleLimit)
        : null;
    final showRawStroke = shouldShowDotStroke(
      sampleLimit: sampleLimit,
      spots: rawSampleSpots,
    );
    final showSmoothStroke = shouldShowDotStroke(
      sampleLimit: sampleLimit,
      spots: smoothSampleSpots,
    );

    return _LapChartCard(
      title: 'lat(t)',
      subtitle: '原始 vs 平滑後偏移',
      legend: const [
        _LegendEntry(label: 'Raw', color: Color(0xFF78A1FF)),
        _LegendEntry(label: 'Smooth', color: Color(0xFF4ADE80)),
      ],
      child: LineChart(
        LineChartData(
          minX: time.first,
          maxX: time.last,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.black.withValues(alpha: 0.7),
              getTooltipItems: (spots) {
                final items = <LineTooltipItem?>[];
                var shown = false;
                for (final spot in spots) {
                  if (shown || spot.bar.barWidth == 0) {
                    items.add(null);
                    continue;
                  }
                  items.add(
                    LineTooltipItem(
                      '${spot.y.toStringAsFixed(2)} m @ ${spot.x.toStringAsFixed(2)} s',
                      const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  );
                  shown = true;
                }
                return items;
              },
            ),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: _gridInterval(minY, maxY, fallback: 0.2),
            getDrawingHorizontalLine: (value) => FlLine(
              color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: colors.onSurface.withValues(alpha: isDark ? 0.24 : 0.18)),
              bottom: BorderSide(color: colors.onSurface.withValues(alpha: isDark ? 0.24 : 0.18)),
              right: const BorderSide(color: Colors.transparent),
              top: const BorderSide(color: Colors.transparent),
            ),
          ),
          titlesData: _buildTitles(
            context,
            bottomLabel: '時間 (s)',
            leftFormatter: (value) => value.toStringAsFixed(1),
          ),
          rangeAnnotations: RangeAnnotations(
            verticalRangeAnnotations: annotations,
          ),
          lineBarsData: [
            LineChartBarData(
              spots: rawSpots,
              isCurved: false,
              color: const Color(0xFF78A1FF),
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: smoothSpots,
              isCurved: false,
              color: const Color(0xFF4ADE80),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
            ),
            if (rawSampleSpots != null)
              LineChartBarData(
                spots: rawSampleSpots,
                isCurved: false,
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 3,
                        color: const Color(0xFF78A1FF),
                        strokeWidth: showRawStroke ? 1 : 0,
                        strokeColor: showRawStroke
                            ? (isDark ? Colors.black : Colors.white)
                            : Colors.transparent,
                      ),
                ),
              ),
            if (smoothSampleSpots != null)
              LineChartBarData(
                spots: smoothSampleSpots,
                isCurved: false,
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 3,
                        color: const Color(0xFF4ADE80),
                        strokeWidth: showSmoothStroke ? 1 : 0,
                        strokeColor: showSmoothStroke
                            ? (isDark ? Colors.black : Colors.white)
                            : Colors.transparent,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LatPsdChart extends StatelessWidget {
  const _LatPsdChart({
    required this.lap,
    required this.showSamples,
    required this.sampleLimit,
    required this.maxPoints,
  });

  final PerLapOffsetLap lap;
  final bool showSamples;
  final int? sampleLimit;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    final freq = lap.fft.frequencyHz;
    final psd = lap.fft.psdDb;
    if (freq.isEmpty || psd.isEmpty) {
      return const _LapChartCard(
        title: 'PSD lat(t)',
        subtitle: '走路區段的頻譜 (dB)',
        reserveLegendSpace: true,
        child: _EmptyChartMessage('缺少 FFT / PSD 資料'),
      );
    }

    final unlimitSamples = showSamples && sampleLimit == null;
    final baseSpots = _buildSpots(
      freq,
      psd,
      maxPoints: unlimitSamples ? freq.length : maxPoints,
    );
    final sampleSpots = showSamples
        ? _limitFlSpots(baseSpots, sampleLimit)
        : null;
    final spots = sampleSpots ?? baseSpots;
    final showStroke = shouldShowDotStroke(
      sampleLimit: sampleLimit,
      spots: sampleSpots,
    );
    final yRange = _computeRange(psd);
    final minY = yRange.min - 3;
    final maxY = yRange.max + 3;
    final peakFreq = lap.fft.peakFrequencyOrNull;
    final freqSpan = lap.fft.band.length >= 2
        ? lap.fft.band[1] - lap.fft.band[0]
        : freq.last - freq.first;
    final verticalInterval = freqSpan > 0
        ? freqSpan / 4
        : math.max(0.1, (freq.last - freq.first).abs() / 4);

    return _LapChartCard(
      title: 'PSD lat(t)',
      subtitle: '走路區段的頻譜 (dB)',
      reserveLegendSpace: true,
      child: LineChart(
        LineChartData(
          minX: freq.first,
          maxX: freq.last,
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.black.withValues(alpha: 0.7),
              getTooltipItems: (spots) {
                final items = <LineTooltipItem?>[];
                var shown = false;
                for (final spot in spots) {
                  if (shown || spot.bar.barWidth == 0) {
                    items.add(null);
                    continue;
                  }
                  items.add(
                    LineTooltipItem(
                      '${spot.x.toStringAsFixed(2)} Hz\n${spot.y.toStringAsFixed(1)} dB',
                      const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  );
                  shown = true;
                }
                return items;
              },
            ),
          ),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              if (peakFreq != null)
                VerticalLine(
                  x: peakFreq,
                  color: const Color(0xFFFFC857),
                  strokeWidth: 1,
                  dashArray: [8, 4],
                  label: VerticalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(bottom: 8),
                    style: const TextStyle(
                      color: Color(0xFFFFC857),
                      fontSize: 11,
                    ),
                    labelResolver: (line) =>
                        'peak ${peakFreq.toStringAsFixed(2)} Hz',
                  ),
                ),
            ],
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            horizontalInterval: _gridInterval(minY, maxY, fallback: 5),
            getDrawingHorizontalLine: (value) => FlLine(
              color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
              strokeWidth: 1,
            ),
            drawVerticalLine: true,
            verticalInterval: verticalInterval,
            getDrawingVerticalLine: (value) => FlLine(
              color: colors.onSurface.withValues(alpha: isDark ? 0.04 : 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: colors.onSurface.withValues(alpha: isDark ? 0.24 : 0.18)),
              bottom: BorderSide(color: colors.onSurface.withValues(alpha: isDark ? 0.24 : 0.18)),
              right: const BorderSide(color: Colors.transparent),
              top: const BorderSide(color: Colors.transparent),
            ),
          ),
          titlesData: _buildTitles(
            context,
            bottomLabel: '頻率 (Hz)',
            leftFormatter: (value) => value.toStringAsFixed(0),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFFF8C42),
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
            if (sampleSpots != null)
              LineChartBarData(
                spots: sampleSpots,
                isCurved: false,
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 3,
                        color: const Color(0xFFFF8C42),
                        strokeWidth: showStroke ? 1 : 0,
                        strokeColor: showStroke
                            ? (isDark ? Colors.black : Colors.white)
                            : Colors.transparent,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThetaChart extends StatelessWidget {
  const _ThetaChart({
    required this.lap,
    required this.showSamples,
    required this.sampleLimit,
    required this.maxPoints,
  });

  final PerLapOffsetLap lap;
  final bool showSamples;
  final int? sampleLimit;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    final time = lap.timeSeconds;
    final theta = lap.thetaDegrees;
    if (time.isEmpty || theta.isEmpty) {
      return const _LapChartCard(
        title: 'θ(t)',
        subtitle: '圈起始為 0° 的骨盆朝向',
        reserveLegendSpace: true,
        child: _EmptyChartMessage('缺少 θ(t) 資料'),
      );
    }

    final unlimitSamples = showSamples && sampleLimit == null;
    final spots = _buildSpots(
      time,
      theta,
      maxPoints: unlimitSamples ? time.length : maxPoints,
    );
    final sampleSpots = showSamples ? _limitFlSpots(spots, sampleLimit) : null;
    final yRange = _computeRange(theta);
    final padding = yRange.delta == 0 ? 5 : yRange.delta * 0.15;

    final annotations = _buildRegionAnnotations(
      time,
      lap,
      turnColor: const Color(0xFF95B7FF).withValues(alpha: 0.24),
    );

    final showStroke = shouldShowDotStroke(
      sampleLimit: sampleLimit,
      spots: sampleSpots,
    );

    return _LapChartCard(
      title: 'θ(t)',
      subtitle: '圈起始為 0° 的骨盆朝向',
      reserveLegendSpace: true,
      child: LineChart(
        LineChartData(
          minX: time.first,
          maxX: time.last,
          minY: yRange.min - padding,
          maxY: yRange.max + padding,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.black.withValues(alpha: 0.7),
              getTooltipItems: (spots) {
                final items = <LineTooltipItem?>[];
                var shown = false;
                for (final spot in spots) {
                  if (shown || spot.bar.barWidth == 0) {
                    items.add(null);
                    continue;
                  }
                  items.add(
                    LineTooltipItem(
                      '${spot.y.toStringAsFixed(1)}° @ ${spot.x.toStringAsFixed(2)} s',
                      const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  );
                  shown = true;
                }
                return items;
              },
            ),
          ),
          gridData: FlGridData(
            drawHorizontalLine: true,
            horizontalInterval: _gridInterval(
              yRange.min - padding,
              yRange.max + padding,
              fallback: 10,
            ),
            getDrawingHorizontalLine: (value) => FlLine(
              color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: colors.onSurface.withValues(alpha: isDark ? 0.24 : 0.18)),
              bottom: BorderSide(color: colors.onSurface.withValues(alpha: isDark ? 0.24 : 0.18)),
              right: const BorderSide(color: Colors.transparent),
              top: const BorderSide(color: Colors.transparent),
            ),
          ),
          titlesData: _buildTitles(
            context,
            bottomLabel: '時間 (s)',
            leftFormatter: (value) => value.toStringAsFixed(0),
          ),
          rangeAnnotations: RangeAnnotations(
            verticalRangeAnnotations: annotations,
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: const Color(0xFF60A5FA),
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
            if (sampleSpots != null)
              LineChartBarData(
                spots: sampleSpots,
                isCurved: false,
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 3,
                        color: const Color(0xFF60A5FA),
                        // 當樣本數超過閾值時才顯示描邊，避免點太多變黑
                        strokeWidth: showStroke ? 1 : 0,
                        strokeColor: showStroke
                            ? (isDark ? Colors.black : Colors.white)
                            : Colors.transparent,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LapChartCard extends StatelessWidget {
  const _LapChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.legend,
    this.reserveLegendSpace = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<_LegendEntry>? legend;
  final bool reserveLegendSpace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            if (legend != null) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 12, children: legend!),
            ] else if (reserveLegendSpace) ...[
              const SizedBox(height: 12),
              const SizedBox(height: 20),
            ],
            const SizedBox(height: 12),
            SizedBox(height: 260, child: child),
          ],
        ),
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EmptyChartMessage extends StatelessWidget {
  const _EmptyChartMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Center(
      child: Text(message, style: TextStyle(color: colors.onSurfaceVariant)),
    );
  }
}

class _RangeStats {
  const _RangeStats(this.min, this.max);

  final double min;
  final double max;

  double get delta => max - min;
}

_RangeStats _computeRange(List<double> values) {
  if (values.isEmpty) {
    return const _RangeStats(0, 0);
  }
  var minValue = double.infinity;
  var maxValue = -double.infinity;
  for (final value in values) {
    if (!value.isFinite) {
      continue;
    }
    if (value < minValue) {
      minValue = value;
    }
    if (value > maxValue) {
      maxValue = value;
    }
  }
  if (!minValue.isFinite || !maxValue.isFinite) {
    return const _RangeStats(0, 0);
  }
  return _RangeStats(minValue, maxValue);
}

double _gridInterval(
  double min,
  double max, {
  double fallback = 1,
  int targetLines = 8,
}) {
  final delta = (max - min).abs();
  if (delta <= 0) {
    return fallback;
  }
  final step = delta / targetLines;
  if (step <= 0) {
    return fallback;
  }
  final magnitude = math.pow(10, step.log10().floor()).toDouble();
  final normalized = (step / magnitude).ceil();
  return math.max(fallback, normalized * magnitude);
}

extension _Log10Extension on double {
  double log10() => math.log(this) / math.ln10;
}

FlTitlesData _buildTitles(
  BuildContext context, {
  required String bottomLabel,
  required String Function(double) leftFormatter,
}) {
  final colors = context.colorScheme;
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      axisNameWidget: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text(
          bottomLabel,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
      ),
      sideTitles: SideTitles(
        showTitles: true,
        interval: null,
        getTitlesWidget: (value, meta) => Text(
          value.abs() >= 10
              ? value.toStringAsFixed(0)
              : value.toStringAsFixed(1),
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
        ),
        reservedSize: 40,
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            leftFormatter(value),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ),
        reservedSize: 40,
      ),
    ),
  );
}

List<VerticalRangeAnnotation> _buildRegionAnnotations(
  List<double> times,
  PerLapOffsetLap lap, {
  required Color turnColor,
}) {
  VerticalRangeAnnotation? build(LapRegion region, Color color) {
    if (times.isEmpty || !region.isValid) {
      return null;
    }
    final startIndex = region.startIndex.clamp(0, times.length - 1);
    final endIndex = region.endIndex.clamp(0, times.length - 1);
    if (endIndex <= startIndex) {
      return null;
    }
    final x1 = times[startIndex];
    final x2 = times[endIndex];
    if ((x2 - x1).abs() <= 0) {
      return null;
    }
    return VerticalRangeAnnotation(x1: x1, x2: x2, color: color);
  }

  final annotations = <VerticalRangeAnnotation>[];
  void addRegion(LapRegion region, Color color) {
    final annotation = build(region, color);
    if (annotation != null) {
      annotations.add(annotation);
    }
  }

  addRegion(lap.coneTurn, turnColor);
  addRegion(lap.chairTurn, turnColor);
  return annotations;
}

List<FlSpot> _buildSpots(
  List<double> xs,
  List<double> ys, {
  int maxPoints = 800,
}) {
  final length = math.min(xs.length, ys.length);
  if (length == 0) {
    return const <FlSpot>[];
  }
  final step = math.max(1, (length / maxPoints).ceil());
  final spots = <FlSpot>[];
  for (var i = 0; i < length; i += step) {
    final x = xs[i];
    final y = ys[i];
    if (x.isFinite && y.isFinite) {
      spots.add(FlSpot(x, y));
    }
  }
  if ((length - 1) % step != 0) {
    final x = xs[length - 1];
    final y = ys[length - 1];
    if (x.isFinite && y.isFinite) {
      spots.add(FlSpot(x, y));
    }
  }
  return spots;
}

List<FlSpot> _limitFlSpots(List<FlSpot> spots, int? limit) {
  if (limit == null || spots.length <= limit) {
    return spots;
  }
  final step = (spots.length / limit).ceil();
  final limited = <FlSpot>[];
  for (var i = 0; i < spots.length; i += step) {
    limited.add(spots[i]);
  }
  if ((spots.length - 1) % step != 0) {
    limited.add(spots.last);
  }
  return limited;
}
