import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';

enum _OverviewMetric { lateralOffset, pelvisAngle }

/// 提供偏移分析的全局視圖，將所有圈數串接成單一時序。
class PerLapOffsetOverviewChart extends StatelessWidget {
  const PerLapOffsetOverviewChart({
    required this.laps,
    required this.maxPoints,
    super.key,
  });

  final List<PerLapOffsetLap> laps;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    return _PerLapOverviewChart(
      laps: laps,
      metric: _OverviewMetric.lateralOffset,
      maxPoints: maxPoints,
    );
  }
}

/// 顯示骨盆角度 θ(t) 的全景圖。
class PerLapAngleOverviewChart extends StatelessWidget {
  const PerLapAngleOverviewChart({
    required this.laps,
    required this.maxPoints,
    super.key,
  });

  final List<PerLapOffsetLap> laps;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    return _PerLapOverviewChart(
      laps: laps,
      metric: _OverviewMetric.pelvisAngle,
      maxPoints: maxPoints,
    );
  }
}

class _PerLapOverviewChart extends ConsumerStatefulWidget {
  const _PerLapOverviewChart({
    required this.laps,
    required this.metric,
    required this.maxPoints,
  });

  final List<PerLapOffsetLap> laps;
  final _OverviewMetric metric;
  final int maxPoints;

  @override
  ConsumerState<_PerLapOverviewChart> createState() =>
      _PerLapOverviewChartState();
}

class _PerLapOverviewChartState extends ConsumerState<_PerLapOverviewChart> {
  _OverviewTooltip? _tooltip;
  int? _hoverLapIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final data = _buildOverviewData(widget.laps, maxPoints: widget.maxPoints);
    if (data.points.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedLap = ref.watch(perLapOffsetSelectedLapProvider);
    final accent = DashboardAccentColors.of(context);
    final chartColor = _lineColor(accent);
    final highlightLap = _hoverLapIndex ?? selectedLap;
    final highlightRange = highlightLap == null
        ? null
        : data.ranges
              .firstWhere(
                (range) => range.lapIndex == highlightLap,
                orElse: () => _LapRange.empty,
              )
              .nonEmptyOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: context.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedLap != null) ...[
                  const SizedBox(width: 16),
                  Chip(
                    label: Text('目前圈數：Lap $selectedLap'),
                    side: BorderSide(color: colors.outlineVariant),
                    backgroundColor: colors.surfaceContainerLow,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final tooltip = _tooltip;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      LineChart(
                        LineChartData(
                          minX: data.minX,
                          maxX: data.maxX,
                          minY: data.minY,
                          maxY: data.maxY,
                          gridData: FlGridData(
                            drawHorizontalLine: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.05),
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
                          rangeAnnotations: RangeAnnotations(
                            verticalRangeAnnotations: [
                              if (highlightRange != null)
                                VerticalRangeAnnotation(
                                  x1: highlightRange.start,
                                  x2: highlightRange.end,
                                  color: colors.onSurface.withValues(alpha: isDark ? 0.05 : 0.08),
                                ),
                            ],
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
                                reservedSize: 48,
                                getTitlesWidget: (value, meta) => Text(
                                  _formatYAxis(value),
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: data.maxX > 180 ? 30 : 15,
                                getTitlesWidget: (value, meta) => Text(
                                  '${value.toStringAsFixed(0)} s',
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: false,
                            touchSpotThreshold: 18,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipPadding: EdgeInsets.zero,
                              getTooltipItems: (touchedSpots) => [],
                            ),
                            touchCallback: (event, response) =>
                                _handleTouch(event, response, data),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: data.points
                                  .map((point) => point.spot)
                                  .toList(growable: false),
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: chartColor,
                              barWidth: 2.2, // 稍微調細一點點
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    chartColor.withValues(alpha: isDark ? 0.20 : 0.08),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (tooltip != null)
                        Positioned(
                          left: (tooltip.position.dx - 90).clamp(
                            0.0,
                            chartSize.width - 180,
                          ),
                          top: (tooltip.position.dy - 120).clamp(
                            0.0,
                            chartSize.height - 140,
                          ),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () =>
                                  _handleTooltipTap(tooltip.point.lapIndex),
                              child: DashboardGlassTooltip(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lap ${tooltip.point.lapIndex}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTooltipValue(tooltip.point.spot.y),
                                      style: TextStyle(
                                        color: chartColor.computeLuminance() < 0.5 
                                            ? chartColor.withValues(alpha: 0.95)
                                            : chartColor, // 如果顏色太淡則不調整
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tooltip.point.spot.x.toStringAsFixed(2)} s',
                                      style: TextStyle(
                                        color: colors.onSurface.withValues(alpha: 0.72),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _title {
    switch (widget.metric) {
      case _OverviewMetric.lateralOffset:
        return 'Lateral Offset 全景圖';
      case _OverviewMetric.pelvisAngle:
        return 'Pelvis Angle 全景圖';
    }
  }

  String get _subtitle {
    switch (widget.metric) {
      case _OverviewMetric.lateralOffset:
        return '將所有圈數串成連續時序，點選任一區段即可跳至細節圖。';
      case _OverviewMetric.pelvisAngle:
        return '觀察骨盆朝向 θ(t) 的整體變化，點選任一區段即可跳至細節圖。';
    }
  }

  Color _lineColor(DashboardAccentColors accent) {
    switch (widget.metric) {
      case _OverviewMetric.lateralOffset:
        return accent.success;
      case _OverviewMetric.pelvisAngle:
        return accent.warning;
    }
  }

  String _formatYAxis(double value) {
    switch (widget.metric) {
      case _OverviewMetric.lateralOffset:
        return '${value.toStringAsFixed(1)} m';
      case _OverviewMetric.pelvisAngle:
        return '${value.toStringAsFixed(0)}°';
    }
  }

  String _formatTooltipValue(double value) {
    switch (widget.metric) {
      case _OverviewMetric.lateralOffset:
        return '${value.toStringAsFixed(2)} m';
      case _OverviewMetric.pelvisAngle:
        return '${value.toStringAsFixed(1)}°';
    }
  }

  void _handleTouch(
    FlTouchEvent event,
    LineTouchResponse? response,
    _OverviewData data,
  ) {
    final spots = response?.lineBarSpots;
    if (spots == null || spots.isEmpty) {
      if (_tooltip != null || _hoverLapIndex != null) {
        setState(() {
          _tooltip = null;
          _hoverLapIndex = null;
        });
      }
      return;
    }

    final point = _resolvePointFromTouch(spots.first, data);
    if (point == null) {
      setState(() {
        _tooltip = null;
        _hoverLapIndex = null;
      });
      return;
    }
    final lapIndex = point.lapIndex;
    final localPos = event.localPosition ?? Offset.zero;

    if (event is FlPanDownEvent ||
        event is FlPanStartEvent ||
        event is FlPanUpdateEvent ||
        event is FlTapDownEvent ||
        event is FlPointerHoverEvent ||
        event is FlLongPressStart ||
        event is FlLongPressMoveUpdate) {
      setState(() {
        _hoverLapIndex = lapIndex;
        _tooltip = _OverviewTooltip(point: point, position: localPos);
      });
      return;
    }

    if (event is FlTapUpEvent ||
        event is FlPanEndEvent ||
        event is FlLongPressEnd) {
      setState(() {
        _hoverLapIndex = null;
        _tooltip = null;
      });
      ref.read(perLapOffsetSelectedLapProvider.notifier).select(lapIndex);
      return;
    }

    if (event is FlTapCancelEvent || event is FlPanCancelEvent) {
      setState(() {
        _hoverLapIndex = null;
        _tooltip = null;
      });
    }
  }

  /// 解析觸控點對應的圈數，當 FL Chart 回傳 -1 時改用最接近的 x。
  _OverviewPoint? _resolvePointFromTouch(
    LineBarSpot touched,
    _OverviewData data,
  ) {
    final spotIndex = touched.spotIndex;
    if (spotIndex >= 0 && spotIndex < data.points.length) {
      return data.points[spotIndex];
    }
    return _findClosestPointByX(data.points, touched.x);
  }

  _OverviewPoint? _findClosestPointByX(
    List<_OverviewPoint> points,
    double targetX,
  ) {
    if (points.isEmpty) {
      return null;
    }
    var closest = points.first;
    var closestDelta = (closest.spot.x - targetX).abs();
    for (final point in points.skip(1)) {
      final delta = (point.spot.x - targetX).abs();
      if (delta < closestDelta) {
        closest = point;
        closestDelta = delta;
      }
    }
    return closest;
  }

  _OverviewData _buildOverviewData(
    List<PerLapOffsetLap> laps, {
    required int maxPoints,
  }) {
    var points = <_OverviewPoint>[];
    final ranges = <_LapRange>[];
    var cumulativeTime = 0.0;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;

    for (final lap in laps) {
      final times = lap.timeSeconds;
      final series = _seriesForLap(lap);
      if (times.isEmpty || series.isEmpty || series.length != times.length) {
        continue;
      }
      final start = cumulativeTime;
      for (var i = 0; i < times.length; i++) {
        final x = cumulativeTime + times[i];
        final y = series[i];
        points.add(_OverviewPoint(lapIndex: lap.lapIndex, spot: FlSpot(x, y)));
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
      final end = cumulativeTime + times.last;
      ranges.add(_LapRange(lapIndex: lap.lapIndex, start: start, end: end));
      cumulativeTime = end;
    }

    if (points.isEmpty) {
      return _OverviewData.empty;
    }

    if (maxPoints > 0 && points.length > maxPoints) {
      final step = (points.length / maxPoints).ceil();
      final sampled = <_OverviewPoint>[];
      for (var i = 0; i < points.length; i += step) {
        sampled.add(points[i]);
      }
      if ((points.length - 1) % step != 0) {
        sampled.add(points.last);
      }
      points = sampled;
    }

    final padding = (maxY - minY).abs() < 1e-6 ? 0.5 : (maxY - minY) * 0.1;

    return _OverviewData(
      points: points,
      ranges: ranges,
      minX: 0,
      maxX: cumulativeTime,
      minY: minY - padding,
      maxY: maxY + padding,
    );
  }

  List<double> _seriesForLap(PerLapOffsetLap lap) {
    switch (widget.metric) {
      case _OverviewMetric.lateralOffset:
        return lap.latSmooth.isNotEmpty ? lap.latSmooth : lap.latRaw;
      case _OverviewMetric.pelvisAngle:
        return lap.thetaDegrees;
    }
  }

  void _handleTooltipTap(int lapIndex) {
    ref.read(perLapOffsetSelectedLapProvider.notifier).select(lapIndex);
    setState(() {
      _hoverLapIndex = null;
      _tooltip = null;
    });
  }
}

class _OverviewPoint {
  const _OverviewPoint({required this.lapIndex, required this.spot});

  final int lapIndex;
  final FlSpot spot;
}

class _OverviewData {
  const _OverviewData({
    required this.points,
    required this.ranges,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final List<_OverviewPoint> points;
  final List<_LapRange> ranges;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  static const empty = _OverviewData(
    points: [],
    ranges: [],
    minX: 0,
    maxX: 0,
    minY: 0,
    maxY: 0,
  );
}

class _OverviewTooltip {
  _OverviewTooltip({required this.point, required this.position});

  final _OverviewPoint point;
  final Offset position;
}

class _LapRange {
  const _LapRange({
    required this.lapIndex,
    required this.start,
    required this.end,
  });

  final int lapIndex;
  final double start;
  final double end;

  static const empty = _LapRange(lapIndex: -1, start: 0, end: 0);

  _LapRange? get nonEmptyOrNull => start == end ? null : this;
}
