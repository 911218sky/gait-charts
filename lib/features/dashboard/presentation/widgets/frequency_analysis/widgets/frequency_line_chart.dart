import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/chart_pan_shortcuts.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/frequency_analysis/widgets/frequency_models.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/frequency_analysis/widgets/frequency_utils.dart';

/// 頻率折線圖元件，支援多系列資料與峰值標記
class FrequencyLineChart extends StatefulWidget {
  const FrequencyLineChart({
    required this.series,
    required this.xLabel,
    required this.yLabel,
    required this.emptyLabel,
    this.maxSamples = 360,
    super.key,
  });

  final List<FrequencySeries> series;
  final String xLabel;
  final String yLabel;
  final String emptyLabel;
  final int maxSamples;

  @override
  State<FrequencyLineChart> createState() => _FrequencyLineChartState();
}

class _FrequencyLineChartState extends State<FrequencyLineChart> {
  static const double _leftTitlesReservedSize = 48;
  static const double _bottomTitlesReservedSize = 28;
  static const double _axisNameSize = 24;
  static const double _minBrushWidthPx = 8;

  _FrequencyTooltip? _tooltip;
  double? _brushStartDx;
  double? _brushEndDx;
  double? _zoomMinX;
  double? _zoomMaxX;

  double _viewMinX = 0;
  double _viewMaxX = 1;
  double _fullMinX = 0;
  double _fullMaxX = 1;

  bool get _isZoomed => _zoomMinX != null || _zoomMaxX != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    final validSeries = widget.series.where((e) => e.hasData).toList(growable: false);
    if (validSeries.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Text(widget.emptyLabel, style: context.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
        ),
      );
    }

    final bars = <LineChartBarData>[];
    final labels = <LineChartBarData, String>{};
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;

    void extendBounds(List<FlSpot> spots) {
      for (final spot in spots) {
        minX = math.min(minX, spot.x);
        maxX = math.max(maxX, spot.x);
        minY = math.min(minY, spot.y);
        maxY = math.max(maxY, spot.y);
      }
    }

    for (final entry in validSeries) {
      final spots = buildFrequencySpots(
        entry.xValues,
        entry.yValues,
        maxPoints: widget.maxSamples,
        priorityX: entry.peaks.map((p) => p.freq),
      );
      if (spots.isEmpty) continue;
      extendBounds(spots);

      final bar = LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.32,
        preventCurveOverShooting: true,
        color: entry.color,
        barWidth: 2.2,
        dotData: const FlDotData(show: false),
      );
      bars.add(bar);
      labels[bar] = entry.label;

      // 峰值標記點
      if (entry.peaks.isNotEmpty) {
        final peakSpots = entry.peaks
            .map((p) => FlSpot(p.freq, p.db))
            .where((s) => s.y.isFinite && s.x.isFinite)
            .toList();
        if (peakSpots.isNotEmpty) {
          extendBounds(peakSpots);
          final dotColor = frequencyPeakDotColor(entry.color);
          bars.add(
            LineChartBarData(
              spots: peakSpots,
              isCurved: false,
              color: Colors.transparent,
              barWidth: 0,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: dotColor,
                  strokeWidth: 1.3,
                  strokeColor: entry.color,
                ),
              ),
            ),
          );
        }
      }
    }

    if (!minX.isFinite || !minY.isFinite) {
      return SizedBox(
        height: 260,
        child: Center(child: Text('無資料', style: TextStyle(color: colors.onSurfaceVariant))),
      );
    }

    final yPadding = (maxY - minY).abs() * 0.12;
    final xPadding = (maxX - minX).abs() * 0.02;
    final fullMinX = minX - xPadding;
    final fullMaxX = maxX + xPadding;
    _fullMinX = fullMinX;
    _fullMaxX = fullMaxX;

    final viewMinX = (_zoomMinX ?? fullMinX).clamp(fullMinX, fullMaxX).toDouble();
    final viewMaxX = (_zoomMaxX ?? fullMaxX).clamp(fullMinX, fullMaxX).toDouble();

    var autoMinY = minY - (yPadding == 0 ? 5 : yPadding);
    var autoMaxY = maxY + (yPadding == 0 ? 5 : yPadding);

    if (_isZoomed) {
      var visibleMinY = double.infinity;
      var visibleMaxY = -double.infinity;
      for (final bar in bars) {
        for (final spot in bar.spots) {
          if (spot.x < viewMinX || spot.x > viewMaxX) continue;
          visibleMinY = math.min(visibleMinY, spot.y);
          visibleMaxY = math.max(visibleMaxY, spot.y);
        }
      }
      if (visibleMinY.isFinite && visibleMaxY.isFinite) {
        final span = (visibleMaxY - visibleMinY).abs();
        final pad = (span * 0.12).clamp(1.0, 12.0).toDouble();
        autoMinY = visibleMinY - (span == 0 ? 5 : pad);
        autoMaxY = visibleMaxY + (span == 0 ? 5 : pad);
      }
    }

    final viewMinY = autoMinY.toDouble();
    final viewMaxY = autoMaxY.toDouble();
    _viewMinX = viewMinX;
    _viewMaxX = viewMaxX;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(validSeries, colors),
        const SizedBox(height: 12),
        _buildControls(colors),
        const SizedBox(height: 8),
        SizedBox(
          height: 320,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
              return _buildChartWithInteraction(
                chartSize, bars, labels, viewMinX, viewMaxX, viewMinY, viewMaxY, colors, isDark,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(List<FrequencySeries> validSeries, ColorScheme colors) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: validSeries.map((entry) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: entry.color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 6),
          Text(entry.label, style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      )).toList(),
    );
  }

  Widget _buildControls(ColorScheme colors) {
    return Row(
      children: [
        FilledButton.tonalIcon(
          onPressed: _isZoomed ? _resetZoom : null,
          icon: const Icon(Icons.restart_alt, size: 16),
          label: const Text('重置縮放'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '提示：在圖上拖曳可放大，雙擊圖表重置',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildChartWithInteraction(
    Size chartSize,
    List<LineChartBarData> bars,
    Map<LineChartBarData, String> labels,
    double viewMinX,
    double viewMaxX,
    double viewMinY,
    double viewMaxY,
    ColorScheme colors,
    bool isDark,
  ) {
    final tooltip = _tooltip;
    final brush = _buildBrushRect(chartSize);
    final tooltipMaxWidth = math.min(180.0, chartSize.width);
    final tooltipMaxHeight = math.min(140.0, chartSize.height);
    final maxTooltipLeft = math.max(0.0, chartSize.width - tooltipMaxWidth);
    final maxTooltipTop = math.max(0.0, chartSize.height - tooltipMaxHeight);

    final Widget chart = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: _resetZoom,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (event.buttons != kPrimaryButton) return;
          setState(() {
            _tooltip = null;
            _brushStartDx = event.localPosition.dx;
            _brushEndDx = event.localPosition.dx;
          });
        },
        onPointerMove: (event) {
          if (_brushStartDx == null) return;
          setState(() => _brushEndDx = event.localPosition.dx);
        },
        onPointerUp: (event) {
          final start = _brushStartDx;
          final end = _brushEndDx;
          if (start != null && end != null) {
            final left = math.min(start, end).clamp(0.0, chartSize.width);
            final right = math.max(start, end).clamp(0.0, chartSize.width);
            if ((right - left) > _minBrushWidthPx) {
              final span = (_viewMaxX - _viewMinX).abs();
              final nextMinX = (_viewMinX + (left / chartSize.width) * span).clamp(_fullMinX, _fullMaxX).toDouble();
              final nextMaxX = (_viewMinX + (right / chartSize.width) * span).clamp(_fullMinX, _fullMaxX).toDouble();
              setState(() {
                _zoomMinX = nextMinX;
                _zoomMaxX = nextMaxX;
                _brushStartDx = null;
                _brushEndDx = null;
              });
              return;
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
            ClipRect(
              child: _buildLineChart(bars, labels, viewMinX, viewMaxX, viewMinY, viewMaxY, colors, isDark),
            ),
            if (brush != null) _buildBrushOverlay(brush, chartSize, colors, isDark),
            if (tooltip != null) _buildTooltipOverlay(tooltip, tooltipMaxWidth, tooltipMaxHeight, maxTooltipLeft, maxTooltipTop, colors),
          ],
        ),
      ),
    );

    return ChartPanShortcuts(
      onArrow: _handleArrow,
      onHold: _handleArrowHold,
      onEscape: () {
        if (_tooltip != null) setState(() => _tooltip = null);
      },
      child: chart,
    );
  }

  Widget _buildLineChart(
    List<LineChartBarData> bars,
    Map<LineChartBarData, String> labels,
    double viewMinX,
    double viewMaxX,
    double viewMinY,
    double viewMaxY,
    ColorScheme colors,
    bool isDark,
  ) {
    return LineChart(
      LineChartData(
        minX: viewMinX,
        maxX: viewMaxX,
        minY: viewMinY,
        maxY: viewMaxY,
        clipData: const FlClipData.all(),
        extraLinesData: ExtraLinesData(
          verticalLines: _tooltip == null
              ? const []
              : [
                  VerticalLine(
                    x: _tooltip!.x,
                    strokeWidth: 1.2,
                    color: colors.onSurface.withValues(alpha: isDark ? 0.35 : 0.45),
                    dashArray: [6, 6],
                  ),
                ],
        ),
        gridData: FlGridData(
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.05),
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
              reservedSize: _leftTitlesReservedSize,
              interval: frequencyGridInterval(viewMinY, viewMaxY, fallback: 5),
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ),
            axisNameSize: _axisNameSize,
            axisNameWidget: Text(widget.yLabel, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: _bottomTitlesReservedSize,
              interval: frequencyGridInterval(viewMinX, viewMaxX, fallback: 0.5),
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ),
            axisNameSize: _axisNameSize,
            axisNameWidget: Text(widget.xLabel, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          ),
        ),
        lineBarsData: bars,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: false,
          touchSpotThreshold: 18,
          touchCallback: (event, response) => _handleTouch(event, response, labels),
          touchTooltipData: LineTouchTooltipData(tooltipPadding: EdgeInsets.zero, getTooltipItems: (touchedSpots) => []),
        ),
      ),
    );
  }

  Widget _buildBrushOverlay(_BrushRect brush, Size chartSize, ColorScheme colors, bool isDark) {
    return Positioned(
      left: brush.left,
      top: 0,
      width: brush.width,
      height: chartSize.height,
      child: IgnorePointer(child: Container(color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12))),
    );
  }

  Widget _buildTooltipOverlay(
    _FrequencyTooltip tooltip,
    double tooltipMaxWidth,
    double tooltipMaxHeight,
    double maxTooltipLeft,
    double maxTooltipTop,
    ColorScheme colors,
  ) {
    return Positioned(
      left: (tooltip.position.dx - tooltipMaxWidth / 2).clamp(0.0, maxTooltipLeft).toDouble(),
      top: (tooltip.position.dy - 120).clamp(0.0, maxTooltipTop).toDouble(),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: tooltipMaxWidth, maxHeight: tooltipMaxHeight),
        child: DashboardGlassTooltip(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tooltip.label.isNotEmpty)
                Text(tooltip.label, style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                '${tooltip.x.toStringAsFixed(2)} Hz / ${tooltip.y.toStringAsFixed(1)} dB',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetZoom() {
    setState(() {
      _zoomMinX = null;
      _zoomMaxX = null;
      _tooltip = null;
      _brushStartDx = null;
      _brushEndDx = null;
    });
  }

  _BrushRect? _buildBrushRect(Size size) {
    if (_brushStartDx == null || _brushEndDx == null) return null;
    final left = math.max(0.0, math.min(_brushStartDx!, _brushEndDx!));
    final right = math.min(size.width, math.max(_brushStartDx!, _brushEndDx!));
    if (right - left <= 0) return null;
    return _BrushRect(left: left, width: right - left);
  }

  void _handleTouch(FlTouchEvent event, LineTouchResponse? response, Map<LineChartBarData, String> labels) {
    if (_brushStartDx != null) return;

    final spots = response?.lineBarSpots;
    if (spots == null || spots.isEmpty) {
      if (_tooltip != null) setState(() => _tooltip = null);
      return;
    }
    if (!_shouldUpdateTooltip(event)) return;

    final mainSpot = spots.firstWhere((s) => s.bar.barWidth > 0, orElse: () => spots.first);
    final label = labels[mainSpot.bar] ?? '';
    final localPos = event.localPosition ?? Offset.zero;
    setState(() => _tooltip = _FrequencyTooltip(label: label, x: mainSpot.x, y: mainSpot.y, position: localPos));
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

  void _handleArrow(int step) {
    if (_isZoomed) _panZoomWindow(step);
  }

  void _handleArrowHold(int step, Duration dt) {
    if (!_isZoomed) return;
    _panZoomWindowHold(step, dt);
  }

  void _panZoomWindow(int step) {
    final span = (_viewMaxX - _viewMinX).abs();
    if (span <= 0) return;
    final delta = span * 0.12 * step;
    final nextMin = (_viewMinX + delta).clamp(_fullMinX, _fullMaxX - span);
    final nextMax = (nextMin + span).clamp(_fullMinX + span, _fullMaxX);
    setState(() {
      _zoomMinX = nextMin.toDouble();
      _zoomMaxX = nextMax.toDouble();
      _tooltip = null;
      _brushStartDx = null;
      _brushEndDx = null;
    });
  }

  void _panZoomWindowHold(int step, Duration dt) {
    final span = (_viewMaxX - _viewMinX).abs();
    if (span <= 0) return;
    final dtSeconds = dt.inMicroseconds / 1e6;
    if (dtSeconds <= 0) return;
    const speedWindowsPerSecond = 0.85;
    final delta = span * speedWindowsPerSecond * dtSeconds * step;
    final nextMin = (_viewMinX + delta).clamp(_fullMinX, _fullMaxX - span).toDouble();
    final nextMax = (nextMin + span).clamp(_fullMinX + span, _fullMaxX).toDouble();
    setState(() {
      _zoomMinX = nextMin;
      _zoomMaxX = nextMax;
      _tooltip = null;
      _brushStartDx = null;
      _brushEndDx = null;
    });
  }
}

class _FrequencyTooltip {
  const _FrequencyTooltip({required this.label, required this.x, required this.y, required this.position});
  final String label;
  final double x;
  final double y;
  final Offset position;
}

class _BrushRect {
  const _BrushRect({required this.left, required this.width});
  final double left;
  final double width;
}
