import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// 呈現 /minutely_cadence_step_length_bars API 的視覺化卡片。
class MinutelyCadenceBarsCard extends StatefulWidget {
  const MinutelyCadenceBarsCard({required this.data, super.key});

  final MinutelyCadenceStepLengthBarsResponse data;

  @override
  State<MinutelyCadenceBarsCard> createState() =>
      _MinutelyCadenceBarsCardState();
}

class _MinutelyCadenceBarsCardState extends State<MinutelyCadenceBarsCard> {
  _MinutelyMetric _selectedMetric = _MinutelyMetric.cadence;

  @override
  Widget build(BuildContext context) {
    final points = widget.data.points;
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final accent = DashboardAccentColors.of(context);
    final avgCadence = _average(widget.data.cadenceSpm);
    final avgStepLength = _average(widget.data.stepLengthMeters);
    final totalSteps = widget.data.stepCounts.fold<int>(
      0,
      (prev, value) => prev + value,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '每分鐘步頻 / 步長',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '觀察復健過程中各分鐘的步頻、步長與步數變化',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SegmentedButton<_MinutelyMetric>(
                  segments: _MinutelyMetric.values
                      .map(
                        (metric) => ButtonSegment<_MinutelyMetric>(
                          value: metric,
                          label: Text(metric.label),
                        ),
                      )
                      .toList(),
                  selected: {_selectedMetric},
                  onSelectionChanged: (value) {
                    final metric = value.first;
                    if (_selectedMetric != metric) {
                      setState(() => _selectedMetric = metric);
                    }
                  },
                  showSelectedIcon: false,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 260,
              child: _MinutelyBarChart(
                points: points,
                metric: _selectedMetric,
                accent: accent,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SummaryTile(
                  title: '平均步頻',
                  value: '${avgCadence.toStringAsFixed(1)} spm',
                  subtitle: '平滑視窗後的平均',
                ),
                _SummaryTile(
                  title: '平均步長',
                  value: '${avgStepLength.toStringAsFixed(2)} m',
                  subtitle: '所有分鐘均值',
                ),
                _SummaryTile(
                  title: '總步數',
                  value: '$totalSteps',
                  subtitle: '左、右腳步數加總',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: points
                  .map((point) => _MinuteStatChip(point: point))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinutelyBarChart extends StatefulWidget {
  const _MinutelyBarChart({
    required this.points,
    required this.metric,
    required this.accent,
  });

  final List<MinutelyCadencePoint> points;
  final _MinutelyMetric metric;
  final DashboardAccentColors accent;

  @override
  State<_MinutelyBarChart> createState() => _MinutelyBarChartState();
}

class _MinutelyBarChartState extends State<_MinutelyBarChart> {
  _BarTooltipState? _tooltip;

  @override
  void didUpdateWidget(covariant _MinutelyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metric != widget.metric) {
      _tooltip = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final points = widget.points;

    // 避免在 build 內額外分配 values list（資料量大時會增加 GC 壓力）。
    var maxValue = 0.0;
    final minuteSet = <int>{};
    for (final point in points) {
      minuteSet.add(point.minute);
      final value = widget.metric.valueOf(point);
      if (value.isFinite && value > maxValue) {
        maxValue = value;
      }
    }
    if (maxValue <= 0) {
      maxValue = 1.0;
    }
    final maxY = maxValue * 1.2;
    final barColor = switch (widget.metric) {
      _MinutelyMetric.cadence => widget.accent.success,
      _MinutelyMetric.stepLength => widget.accent.warning,
      _MinutelyMetric.stepCount => widget.accent.danger,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
        final tooltip = _tooltip;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            RepaintBoundary(
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY / 8).clamp(0.1, 50.0).toDouble(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: colors.onSurface.withValues(alpha: 0.18)),
                      bottom: BorderSide(color: colors.onSurface.withValues(alpha: 0.18)),
                      right: const BorderSide(color: Colors.transparent),
                      top: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 46,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            widget.metric.formatTick(value),
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final intValue = value.toInt();
                          // 以前是 points.any(...)：在 fl_chart 反覆呼叫 tick builder 時會變成 O(n*m)。
                          if (!minuteSet.contains(intValue)) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '第$intValue分',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: points
                      .map(
                        (point) => BarChartGroupData(
                          x: point.minute,
                          barRods: [
                            BarChartRodData(
                              toY: widget.metric.valueOf(point),
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  barColor.withValues(alpha: 0.25),
                                  barColor,
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(growable: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: EdgeInsets.zero,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem('', const TextStyle()),
                    ),
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        setState(() => _tooltip = null);
                        return;
                      }
                      final index = response.spot!.touchedBarGroupIndex;
                      if (index < 0 || index >= points.length) {
                        setState(() => _tooltip = null);
                        return;
                      }
                      final localPos = event.localPosition ?? Offset.zero;
                      setState(() {
                        _tooltip = _BarTooltipState(
                          point: points[index],
                          position: localPos,
                        );
                      });
                    },
                  ),
                ),
              ),
            ),
            if (tooltip != null)
              Positioned(
                left: (tooltip.position.dx - 90).clamp(
                  0.0,
                  (chartSize.width - 180).clamp(0, double.infinity),
                ),
                top: (tooltip.position.dy - 120).clamp(
                  0.0,
                  (chartSize.height - 140).clamp(0, double.infinity),
                ),
                child: DashboardGlassTooltip(
                  child: _MinutelyTooltipContent(
                    point: tooltip.point,
                    metric: widget.metric,
                    value: widget.metric.valueOf(tooltip.point),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BarTooltipState {
  _BarTooltipState({required this.point, required this.position});

  final MinutelyCadencePoint point;
  final Offset position;
}

class _MinutelyTooltipContent extends StatelessWidget {
  const _MinutelyTooltipContent({
    required this.point,
    required this.metric,
    required this.value,
  });

  final MinutelyCadencePoint point;
  final _MinutelyMetric metric;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '第${point.minute}分鐘',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${metric.label} ${metric.formatValue(value)}${metric.unit}',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.90),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '步數 ${point.stepCount}',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.72),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MinuteStatChip extends StatelessWidget {
  const _MinuteStatChip({required this.point});

  final MinutelyCadencePoint point;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12)),
        color: colors.onSurface.withValues(alpha: isDark ? 0.02 : 0.04),
      ),
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '第${point.minute}分鐘',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '步頻：${point.cadenceSpm.toStringAsFixed(1)} spm',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          Text(
            '步長：${point.stepLengthMeters.toStringAsFixed(2)} m',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          Text(
            '步數：${point.stepCount}',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: context.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

enum _MinutelyMetric { cadence, stepLength, stepCount }

extension on _MinutelyMetric {
  String get label {
    switch (this) {
      case _MinutelyMetric.cadence:
        return '步頻';
      case _MinutelyMetric.stepLength:
        return '步長';
      case _MinutelyMetric.stepCount:
        return '步數';
    }
  }

  String get unit {
    switch (this) {
      case _MinutelyMetric.cadence:
        return ' spm';
      case _MinutelyMetric.stepLength:
        return ' m';
      case _MinutelyMetric.stepCount:
        return ' 步';
    }
  }

  String formatValue(double value) {
    switch (this) {
      case _MinutelyMetric.cadence:
        return value.toStringAsFixed(1);
      case _MinutelyMetric.stepLength:
        return value.toStringAsFixed(2);
      case _MinutelyMetric.stepCount:
        return value.toStringAsFixed(0);
    }
  }

  String formatTick(double value) {
    switch (this) {
      case _MinutelyMetric.cadence:
        return value.toStringAsFixed(0);
      case _MinutelyMetric.stepLength:
        return value.toStringAsFixed(1);
      case _MinutelyMetric.stepCount:
        return value.toStringAsFixed(0);
    }
  }

  double valueOf(MinutelyCadencePoint point) {
    switch (this) {
      case _MinutelyMetric.cadence:
        return point.cadenceSpm;
      case _MinutelyMetric.stepLength:
        return point.stepLengthMeters;
      case _MinutelyMetric.stepCount:
        return point.stepCount.toDouble();
    }
  }
}

double _average(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  final sum = values.reduce((value, element) => value + element);
  return sum / values.length;
}
