import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/chart_dots.dart';
import 'package:gait_charts/core/widgets/chart_pan_shortcuts.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/chart/chart_data.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/chart/chart_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/y_height_diff/chart/height_unit.dart';

/// 高度差圖表的內部實作 widget。
class YHeightDiffInternalChart extends StatefulWidget {
  const YHeightDiffInternalChart({
    required this.response,
    required this.accent,
    required this.unit,
    required this.showSamples,
    required this.sampleLimit,
    required this.maxPoints,
    required this.viewRange,
    required this.showDiff,
    required this.strokeThreshold,
    required this.onRangeSelected,
    required this.onResetView,
    super.key,
    this.chartHeight = 320,
  });

  final YHeightDiffResponse response;
  final DashboardAccentColors accent;
  final HeightUnit unit;
  final bool showSamples;
  final int? sampleLimit;
  final int maxPoints;
  final double chartHeight;
  final RangeValues viewRange;
  final bool showDiff;
  final int strokeThreshold;
  final ValueChanged<RangeValues> onRangeSelected;
  final VoidCallback onResetView;

  @override
  State<YHeightDiffInternalChart> createState() => _YHeightDiffInternalChartState();
}

class _YHeightDiffInternalChartState extends State<YHeightDiffInternalChart> {
  ChartTooltipData? _tooltip;
  late YHeightChartData _chartData;
  double? _brushStartDx;
  double? _brushEndDx;

  @override
  void initState() {
    super.initState();
    _chartData = YHeightChartData.fromResponse(
      widget.response,
      widget.accent,
      maxPoints: widget.maxPoints,
      unit: widget.unit,
      showDiff: widget.showDiff,
    );
  }

  @override
  void didUpdateWidget(covariant YHeightDiffInternalChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response != widget.response ||
        oldWidget.accent != widget.accent ||
        oldWidget.maxPoints != widget.maxPoints ||
        oldWidget.unit != widget.unit ||
        oldWidget.showDiff != widget.showDiff) {
      _chartData = YHeightChartData.fromResponse(
        widget.response,
        widget.accent,
        maxPoints: widget.maxPoints,
        unit: widget.unit,
        showDiff: widget.showDiff,
      );
    }
  }

  void _handleArrowPan(int step, {required double fullMinX, required double fullMaxX}) {
    final start = widget.viewRange.start;
    final end = widget.viewRange.end;
    final span = (end - start).abs();
    final fullSpan = (fullMaxX - fullMinX).abs();

    final isZoomed = span < fullSpan - 1e-6 || start > fullMinX + 1e-6 || end < fullMaxX - 1e-6;
    if (!isZoomed || span <= 0 || fullSpan <= 0) return;

    final delta = span * 0.12 * step;
    final nextStart = (start + delta).clamp(fullMinX, fullMaxX - span).toDouble();
    final nextEnd = (nextStart + span).clamp(fullMinX + span, fullMaxX).toDouble();

    setState(() {
      _tooltip = null;
      _brushStartDx = null;
      _brushEndDx = null;
    });
    widget.onRangeSelected(RangeValues(nextStart, nextEnd));
  }

  void _handleArrowHoldPan(int step, Duration dt, {required double fullMinX, required double fullMaxX}) {
    final start = widget.viewRange.start;
    final end = widget.viewRange.end;
    final span = (end - start).abs();
    final fullSpan = (fullMaxX - fullMinX).abs();

    final isZoomed = span < fullSpan - 1e-6 || start > fullMinX + 1e-6 || end < fullMaxX - 1e-6;
    if (!isZoomed || span <= 0 || fullSpan <= 0) return;

    final dtSeconds = dt.inMicroseconds / 1e6;
    if (dtSeconds <= 0) return;

    const speedWindowsPerSecond = 0.85;
    final delta = span * speedWindowsPerSecond * dtSeconds * step;
    final nextStart = (start + delta).clamp(fullMinX, fullMaxX - span).toDouble();
    final nextEnd = (nextStart + span).clamp(fullMinX + span, fullMaxX).toDouble();

    if (_tooltip != null || _brushStartDx != null || _brushEndDx != null) {
      setState(() {
        _tooltip = null;
        _brushStartDx = null;
        _brushEndDx = null;
      });
    }
    widget.onRangeSelected(RangeValues(nextStart, nextEnd));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final chartData = _chartData.applyView(widget.viewRange);

    if (!chartData.hasEnoughPoints) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Text(
            '資料點不足，無法繪製曲線。',
            style: context.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    final series = chartData.series;
    final showSamples = widget.showSamples;
    final sampleLimit = widget.sampleLimit;
    final showDotStroke = shouldShowDotStroke(sampleLimit: sampleLimit, spots: null, threshold: widget.strokeThreshold);
    final dotStrokeWidth = showDotStroke ? 0.6 : 0.0;
    final minY = floorToInterval(chartData.minY - chartData.paddingY, chartData.yInterval);
    final maxY = ceilToInterval(chartData.maxY + chartData.paddingY, chartData.yInterval);

    return SizedBox(
      height: widget.chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tooltip = _tooltip;
          final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
          final brush = _buildBrushRect(chartSize);

          const fullMinX = 0.0;
          final fullMaxX = widget.response.timeSeconds.isNotEmpty ? widget.response.timeSeconds.last : 1.0;

          return ChartPanShortcuts(
            onArrow: (step) => _handleArrowPan(step, fullMinX: fullMinX, fullMaxX: fullMaxX),
            onHold: (step, dt) => _handleArrowHoldPan(step, dt, fullMinX: fullMinX, fullMaxX: fullMaxX),
            onEscape: () {
              if (_tooltip != null) setState(() => _tooltip = null);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () {
                widget.onResetView();
                setState(() {
                  _brushStartDx = null;
                  _brushEndDx = null;
                });
              },
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) {
                  if (event.buttons != kPrimaryButton) return;
                  setState(() {
                    _brushStartDx = event.localPosition.dx;
                    _brushEndDx = event.localPosition.dx;
                  });
                },
                onPointerMove: (event) {
                  if (_brushStartDx == null) return;
                  setState(() => _brushEndDx = event.localPosition.dx);
                },
                onPointerUp: (event) {
                  if (_brushStartDx != null && _brushEndDx != null) {
                    final start = _brushStartDx!;
                    final end = _brushEndDx!;
                    final left = math.min(start, end);
                    final right = math.max(start, end);
                    if ((right - left) > 8) {
                      final minX = chartData.minX + (left / chartSize.width) * (chartData.maxX - chartData.minX);
                      final maxX = chartData.minX + (right / chartSize.width) * (chartData.maxX - chartData.minX);
                      widget.onRangeSelected(RangeValues(minX, maxX));
                    }
                  }
                  setState(() {
                    _brushStartDx = null;
                    _brushEndDx = null;
                  });
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildLineChart(chartData, series, minY, maxY, isDark, colors, showSamples, sampleLimit, dotStrokeWidth),
                    _buildLegend(series, colors),
                    if (brush != null) _buildBrushOverlay(brush, chartSize, colors),
                    if (tooltip != null) _buildTooltip(tooltip, chartSize, colors),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildLineChart(
    YHeightChartData chartData,
    List<ChartSeries> series,
    double minY,
    double maxY,
    bool isDark,
    ColorScheme colors,
    bool showSamples,
    int? sampleLimit,
    double dotStrokeWidth,
  ) {
    return LineChart(
      LineChartData(
        minX: chartData.minX,
        maxX: chartData.maxX,
        minY: minY,
        maxY: maxY,
        extraLinesData: ExtraLinesData(
          verticalLines: _tooltip == null
              ? const []
              : [
                  VerticalLine(
                    x: _tooltip!.time,
                    strokeWidth: 1.2,
                    color: colors.onSurface.withValues(alpha: 0.35),
                    dashArray: [6, 6],
                  ),
                ],
        ),
        gridData: FlGridData(
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: chartData.yInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: colors.onSurface.withValues(alpha: isDark ? 0.18 : 0.25)),
            bottom: BorderSide(color: colors.onSurface.withValues(alpha: isDark ? 0.18 : 0.25)),
            right: const BorderSide(color: Colors.transparent),
            top: const BorderSide(color: Colors.transparent),
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: chartData.yInterval,
              getTitlesWidget: (value, meta) => Text(
                widget.unit.formatAxisValue(value),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: chartData.maxX > 180 ? 30 : 15,
              getTitlesWidget: (value, meta) => Text(
                '${value.toStringAsFixed(0)} s',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: false,
          touchSpotThreshold: 18,
          touchCallback: (event, response) => _handleTouch(event, response, series),
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: EdgeInsets.zero,
            getTooltipItems: (touchedSpots) => [],
          ),
        ),
        lineBarsData: [
          for (final s in series)
            LineChartBarData(
              spots: s.spots,
              isCurved: s.spots.length < widget.strokeThreshold * 6,
              curveSmoothness: 0.35,
              color: s.color,
              barWidth: 2.4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: s.spots.length < widget.strokeThreshold * 6,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [s.color.withValues(alpha: isDark ? 0.15 : 0.06), Colors.transparent],
                ),
              ),
            ),
          if (showSamples)
            for (final s in series)
              LineChartBarData(
                spots: limitFlSpots(s.spots, sampleLimit ?? widget.strokeThreshold),
                isCurved: false,
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 2.5,
                    color: s.color,
                    strokeWidth: dotStrokeWidth > 0 ? 1.0 : 0.0,
                    strokeColor: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildLegend(List<ChartSeries> series, ColorScheme colors) {
    return Positioned(
      top: 4,
      right: 0,
      child: Wrap(
        spacing: 12,
        children: [
          for (final s in series)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 4,
                  decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 6),
                Text(s.label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBrushOverlay(BrushRect brush, Size chartSize, ColorScheme colors) {
    return Positioned(
      left: brush.left,
      top: 0,
      width: brush.width,
      height: chartSize.height,
      child: IgnorePointer(child: Container(color: colors.onSurface.withValues(alpha: 0.08))),
    );
  }

  Widget _buildTooltip(ChartTooltipData tooltip, Size chartSize, ColorScheme colors) {
    return Positioned(
      left: (tooltip.position.dx - 90).clamp(0.0, chartSize.width - 180),
      top: (tooltip.position.dy - 120).clamp(0.0, chartSize.height - 140),
      child: DashboardGlassTooltip(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              't = ${tooltip.time.toStringAsFixed(2)} s',
              style: context.textTheme.bodyMedium?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            for (final entry in tooltip.values.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${entry.key}: ${widget.unit.formatTooltipValue(entry.value)}',
                  style: TextStyle(
                    color: entry.key.contains('Diff')
                        ? widget.accent.danger
                        : entry.key.contains('Left')
                            ? widget.accent.success
                            : widget.accent.warning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  BrushRect? _buildBrushRect(Size size) {
    if (_brushStartDx == null || _brushEndDx == null) return null;
    final left = math.max(0.0, math.min(_brushStartDx!, _brushEndDx!));
    final right = math.min(size.width, math.max(_brushStartDx!, _brushEndDx!));
    if (right - left < 4) return null;
    return BrushRect(left: left, width: right - left);
  }

  void _handleTouch(FlTouchEvent event, LineTouchResponse? response, List<ChartSeries> series) {
    final spots = response?.lineBarSpots;
    if (spots == null || spots.isEmpty) {
      if (_tooltip != null) setState(() => _tooltip = null);
      return;
    }
    if (!_shouldUpdateTooltip(event)) return;

    final mainSpot = spots.first;
    final x = mainSpot.x;
    final values = <String, double>{};
    for (final s in series) {
      final nearest = _nearestSpot(s.spots, x);
      if (nearest != null) values[s.label] = nearest.y;
    }
    final localPos = event.localPosition ?? Offset.zero;
    setState(() => _tooltip = ChartTooltipData(time: x, values: values, position: localPos));
  }

  FlSpot? _nearestSpot(List<FlSpot> spots, double targetX) {
    if (spots.isEmpty) return null;
    var lo = 0;
    var hi = spots.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (spots[mid].x < targetX) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final idx = lo;
    final prevIdx = (idx - 1).clamp(0, spots.length - 1);
    final nextIdx = idx.clamp(0, spots.length - 1);
    final prev = spots[prevIdx];
    final next = spots[nextIdx];
    return (targetX - prev.x).abs() <= (next.x - targetX).abs() ? prev : next;
  }

  bool _shouldUpdateTooltip(FlTouchEvent event) {
    return event is FlPanDownEvent ||
        event is FlPanStartEvent ||
        event is FlPanUpdateEvent ||
        event is FlTapDownEvent ||
        event is FlPointerHoverEvent ||
        event is FlLongPressStart ||
        event is FlLongPressMoveUpdate;
  }
}
