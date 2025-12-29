import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/providers/chart_config_provider.dart';
import 'package:gait_charts/core/widgets/app_dropdown.dart';
import 'package:gait_charts/core/widgets/chart_pan_shortcuts.dart';
import 'package:gait_charts/core/widgets/chart_dots.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

enum HeightUnit { cm, m }

extension HeightUnitFormatting on HeightUnit {
  double get yScale => switch (this) {
    .cm => 100,
    .m => 1,
  };

  String get label => switch (this) {
    .cm => 'cm',
    .m => 'm',
  };

  String formatAxisValue(double value) => switch (this) {
    .cm => '${value.toStringAsFixed(0)} $label',
    .m => '${value.toStringAsFixed(2)} $label',
  };

  String formatTooltipValue(double value) => switch (this) {
    .cm => '${value.toStringAsFixed(1)} $label',
    .m => '${value.toStringAsFixed(3)} $label',
  };
}

/// 包裝高度差趨勢圖的卡片。
class YHeightDiffChartSection extends ConsumerStatefulWidget {
  const YHeightDiffChartSection({
    required this.response,
    required this.unit,
    required this.onUnitChanged,
    super.key,
  });

  final YHeightDiffResponse response;
  final HeightUnit unit;
  final ValueChanged<HeightUnit> onUnitChanged;

  @override
  ConsumerState<YHeightDiffChartSection> createState() =>
      _YHeightDiffChartSectionState();
}

class _YHeightDiffChartSectionState
    extends ConsumerState<YHeightDiffChartSection> {
  bool _showSamples = false;
  int? _sampleLimit = 120;
  RangeValues? _viewRange;
  bool _showDiff = true;

  @override
  Widget build(BuildContext context) {
    final accent = DashboardAccentColors.of(context);
    final response = widget.response;
    final chartConfig = ref.watch(chartConfigProvider);
    final maxPoints = chartConfig.yHeightDiffMaxPoints;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildChartContent(
          chartHeight: 320,
          accent: accent,
          response: response,
          maxPoints: maxPoints,
        ),
      ),
    );
  }

  Widget _buildChartContent({
    required double chartHeight,
    DashboardAccentColors? accent,
    YHeightDiffResponse? response,
    int? maxPoints,
  }) {
    final colors = context.colorScheme;
    final effectiveResponse = response ?? widget.response;
    final effectiveAccent = accent ?? DashboardAccentColors.of(context);
    final effectiveMaxPoints = effectiveResponse.timeSeconds.length;
    final strokeThreshold = ref.read(chartConfigProvider).yHeightDiffMaxPoints;
    final totalDuration = effectiveResponse.timeSeconds.isNotEmpty
        ? effectiveResponse.timeSeconds.last
        : 0.0;
    final fullRange = RangeValues(0, totalDuration > 0 ? totalDuration : 1);
    final viewRange = _clampRange(_viewRange, fullRange);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '高度差趨勢',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '三條曲線同步呈現：左、右高度與差值，預設已平移到 0 起點。',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Chip(
              label: Text(
                'Joints ${effectiveResponse.leftJoint} / ${effectiveResponse.rightJoint}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (totalDuration > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 放在最顯眼的位置：使用者縮放/拖曳後最常用的動作就是「重置」。
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() => _viewRange = null),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重置區間'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '區間：${viewRange.start.toStringAsFixed(1)} – ${viewRange.end.toStringAsFixed(1)} s',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '提示：在圖上拖曳可放大，雙擊圖表重置',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '顯示 Diff',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: _showDiff,
              onChanged: (value) => setState(() => _showDiff = value),
            ),
            const SizedBox(width: 24),
            Text(
              '單位',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            SegmentedButton<HeightUnit>(
              segments: const [
                ButtonSegment(
                  value: HeightUnit.cm,
                  label: Text('cm'),
                  tooltip: '以公分 (cm) 顯示高度',
                ),
                ButtonSegment(
                  value: HeightUnit.m,
                  label: Text('m'),
                  tooltip: '以公尺 (m) 顯示高度',
                ),
              ],
              selected: {widget.unit},
              showSelectedIcon: false,
              onSelectionChanged: (values) =>
                  widget.onUnitChanged(values.first),
            ),
            const SizedBox(width: 24),
            Text(
              '顯示取樣點',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: _showSamples,
              onChanged: (value) => setState(() => _showSamples = value),
            ),
            const SizedBox(width: 24),
            Text(
              '最多點數',
              style: context.textTheme.bodySmall?.copyWith(
                color: _showSamples ? colors.onSurface : colors.onSurface.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: AppSelect<int?>(
                value: _sampleLimit,
                items: const [60, 120, 240, null],
                itemLabelBuilder: (item) => item?.toString() ?? '不限制',
                enabled: _showSamples,
                onChanged: _showSamples
                    ? (value) => setState(() => _sampleLimit = value)
                    : null,
                menuWidth: const BoxConstraints(minWidth: 100, maxWidth: 140),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _YHeightDiffChart(
          response: effectiveResponse,
          accent: effectiveAccent,
          unit: widget.unit,
          showSamples: _showSamples,
          sampleLimit: _sampleLimit,
          maxPoints: effectiveMaxPoints,
          viewRange: viewRange,
          showDiff: _showDiff,
          strokeThreshold: strokeThreshold,
          onRangeSelected: (range) => setState(() => _viewRange = range),
          onResetView: () => setState(() => _viewRange = null),
          chartHeight: chartHeight,
        ),
      ],
    );
  }

  RangeValues _clampRange(RangeValues? value, RangeValues full) {
    if (value == null) return full;
    var start = value.start.clamp(full.start, full.end);
    var end = value.end.clamp(full.start, full.end);
    if (end - start < 1e-3) {
      return full;
    }
    if (start > end) {
      final temp = start;
      start = end;
      end = temp;
    }
    return RangeValues(start, end);
  }
}

class _YHeightDiffChart extends StatefulWidget {
  const _YHeightDiffChart({
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
  State<_YHeightDiffChart> createState() => _YHeightDiffChartState();
}

class _YHeightDiffChartState extends State<_YHeightDiffChart> {
  _TooltipData? _tooltip;
  late _YHeightChartData _chartData;
  double? _brushStartDx;
  double? _brushEndDx;

  void _handleArrowPan(
    int step, {
    required double fullMinX,
    required double fullMaxX,
  }) {
    final start = widget.viewRange.start;
    final end = widget.viewRange.end;
    final span = (end - start).abs();
    final fullSpan = (fullMaxX - fullMinX).abs();

    // 只有在「已放大/縮放」時才平移畫面，避免在全域範圍時造成困惑。
    final isZoomed =
        span < fullSpan - 1e-6 || start > fullMinX + 1e-6 || end < fullMaxX - 1e-6;
    if (!isZoomed || span <= 0 || fullSpan <= 0) {
      return;
    }

    // 一次平移視窗寬度的 12%，手感接近「按住鍵盤微移」。
    final delta = span * 0.12 * step;
    final nextStart =
        (start + delta).clamp(fullMinX, fullMaxX - span).toDouble();
    final nextEnd =
        (nextStart + span).clamp(fullMinX + span, fullMaxX).toDouble();

    // 清掉 brush/tooltip，避免視覺上殘留到新視窗。
    setState(() {
      _tooltip = null;
      _brushStartDx = null;
      _brushEndDx = null;
    });
    widget.onRangeSelected(RangeValues(nextStart, nextEnd));
  }

  void _handleArrowHoldPan(
    int step,
    Duration dt, {
    required double fullMinX,
    required double fullMaxX,
  }) {
    final start = widget.viewRange.start;
    final end = widget.viewRange.end;
    final span = (end - start).abs();
    final fullSpan = (fullMaxX - fullMinX).abs();

    final isZoomed =
        span < fullSpan - 1e-6 || start > fullMinX + 1e-6 || end < fullMaxX - 1e-6;
    if (!isZoomed || span <= 0 || fullSpan <= 0) {
      return;
    }

    final dtSeconds = dt.inMicroseconds / 1e6;
    if (dtSeconds <= 0) {
      return;
    }

    // 平移速度：以「視窗寬度 / 秒」表示，調整後長按手感更順。
    const speedWindowsPerSecond = 0.85;
    final delta = span * speedWindowsPerSecond * dtSeconds * step;

    final nextStart =
        (start + delta).clamp(fullMinX, fullMaxX - span).toDouble();
    final nextEnd =
        (nextStart + span).clamp(fullMinX + span, fullMaxX).toDouble();

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
  void initState() {
    super.initState();
    _chartData = _YHeightChartData.fromResponse(
      widget.response,
      widget.accent,
      maxPoints: widget.maxPoints,
      unit: widget.unit,
      showDiff: widget.showDiff,
    );
  }

  @override
  void didUpdateWidget(covariant _YHeightDiffChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response != widget.response ||
        oldWidget.accent != widget.accent ||
        oldWidget.maxPoints != widget.maxPoints ||
        oldWidget.unit != widget.unit ||
        oldWidget.showDiff != widget.showDiff) {
      _chartData = _YHeightChartData.fromResponse(
        widget.response,
        widget.accent,
        maxPoints: widget.maxPoints,
        unit: widget.unit,
        showDiff: widget.showDiff,
      );
    }
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
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final series = chartData.series;
    final showSamples = widget.showSamples;
    final sampleLimit = widget.sampleLimit;
    final showDotStroke = shouldShowDotStroke(
      sampleLimit: sampleLimit,
      spots: null,
      threshold: widget.strokeThreshold,
    );
    final dotStrokeWidth = showDotStroke ? 0.6 : 0.0;
    final minY = _floorToInterval(
      chartData.minY - chartData.paddingY,
      chartData.yInterval,
    );
    final maxY = _ceilToInterval(
      chartData.maxY + chartData.paddingY,
      chartData.yInterval,
    );
    return SizedBox(
      height: widget.chartHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tooltip = _tooltip;
          final chartSize = Size(constraints.maxWidth, constraints.maxHeight);

          final brush = _buildBrushRect(chartSize);

          final fullMinX = 0.0;
          final fullMaxX = widget.response.timeSeconds.isNotEmpty
              ? widget.response.timeSeconds.last
              : 1.0;

          return ChartPanShortcuts(
            onArrow: (step) => _handleArrowPan(
              step,
              fullMinX: fullMinX,
              fullMaxX: fullMaxX,
            ),
            onHold: (step, dt) => _handleArrowHoldPan(
              step,
              dt,
              fullMinX: fullMinX,
              fullMaxX: fullMaxX,
            ),
            onEscape: () {
              if (_tooltip != null) {
                setState(() => _tooltip = null);
              }
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
                  if (event.buttons != kPrimaryButton) {
                    return;
                  }
                  setState(() {
                    _brushStartDx = event.localPosition.dx;
                    _brushEndDx = event.localPosition.dx;
                  });
                },
                onPointerMove: (event) {
                  if (_brushStartDx == null) return;
                  setState(() {
                    _brushEndDx = event.localPosition.dx;
                  });
                },
                onPointerUp: (event) {
                  if (_brushStartDx != null && _brushEndDx != null) {
                    final start = _brushStartDx!;
                    final end = _brushEndDx!;
                    final left = math.min(start, end);
                    final right = math.max(start, end);
                    if ((right - left) > 8) {
                      final minX =
                          chartData.minX +
                          (left / chartSize.width) *
                              (chartData.maxX - chartData.minX);
                      final maxX =
                          chartData.minX +
                          (right / chartSize.width) *
                              (chartData.maxX - chartData.minX);
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
                  LineChart(
                    LineChartData(
                      minX: chartData.minX,
                      maxX: chartData.maxX,
                      minY: minY,
                      maxY: maxY,
                      extraLinesData: ExtraLinesData(
                        verticalLines: tooltip == null
                            ? const []
                            : [
                                VerticalLine(
                                  x: tooltip.time,
                                  strokeWidth: 1.2,
                                  color: colors.onSurface.withValues(alpha: 0.35),
                                  dashArray: [6, 6],
                                ),
                              ],
                      ),
                      gridData: FlGridData(
                        drawHorizontalLine: true,
                        drawVerticalLine: false, // 移除垂直線讓畫面更清爽，符合 Vercel 風格
                        horizontalInterval: chartData.yInterval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(
                            color: colors.onSurface.withValues(alpha: isDark ? 0.18 : 0.25),
                          ),
                          bottom: BorderSide(
                            color: colors.onSurface.withValues(alpha: isDark ? 0.18 : 0.25),
                          ),
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
                            reservedSize: 52,
                            interval: chartData.yInterval,
                            getTitlesWidget: (value, meta) => Text(
                              widget.unit.formatAxisValue(value),
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
                            interval: chartData.maxX > 180 ? 30 : 15,
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
                        touchCallback: (event, response) =>
                            _handleTouch(event, response, series),
                        touchTooltipData: LineTouchTooltipData(
                          tooltipPadding: EdgeInsets.zero,
                          getTooltipItems: (touchedSpots) => [],
                        ),
                      ),
                      lineBarsData: [
                        for (final s in series)
                          LineChartBarData(
                            spots: s.spots,
                            isCurved:
                                s.spots.length < widget.strokeThreshold * 6,
                            curveSmoothness: 0.35,
                            color: s.color,
                            barWidth: 2.4, // 稍微加粗一點讓線條更紮實
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: s.spots.length < widget.strokeThreshold * 6,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  s.color.withValues(
                                    alpha: isDark ? 0.15 : 0.06, // 亮色模式下降低填充透明度，避免多線重疊時顯得髒
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        if (showSamples)
                          for (final s in series)
                            LineChartBarData(
                              spots: _limitFlSpots(
                                s.spots,
                                sampleLimit ?? widget.strokeThreshold,
                              ),
                              isCurved: false,
                              color: Colors.transparent,
                              barWidth: 0,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                                      radius: 2.5,
                                      color: s.color,
                                      strokeWidth: dotStrokeWidth > 0 ? 1.0 : 0.0,
                                      strokeColor: isDark 
                                          ? Colors.black.withValues(alpha: 0.5) 
                                          : Colors.white, // 亮色模式下用白色邊框讓點更清晰
                                    ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  Positioned(
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
                                height: 4, // 扁平的長方形，看起來更像線條標示
                                decoration: BoxDecoration(
                                  color: s.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.label,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (brush != null)
                    Positioned(
                      left: brush.left,
                      top: 0,
                      width: brush.width,
                      height: chartSize.height,
                      child: IgnorePointer(
                        child: Container(
                          color: colors.onSurface.withValues(alpha: 0.08),
                        ),
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
                      child: DashboardGlassTooltip(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              't = ${tooltip.time.toStringAsFixed(2)} s',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
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
                    ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  _BrushRect? _buildBrushRect(Size size) {
    if (_brushStartDx == null || _brushEndDx == null) return null;
    final left = math.max(0.0, math.min(_brushStartDx!, _brushEndDx!));
    final right = math.min(size.width, math.max(_brushStartDx!, _brushEndDx!));
    if (right - left < 4) return null;
    return _BrushRect(left: left, width: right - left);
  }

  void _handleTouch(
    FlTouchEvent event,
    LineTouchResponse? response,
    List<_Series> series,
  ) {
    final spots = response?.lineBarSpots;
    if (spots == null || spots.isEmpty) {
      if (_tooltip != null) {
        setState(() => _tooltip = null);
      }
      return;
    }

    if (!_shouldUpdateTooltip(event)) {
      return;
    }

    final mainSpot = spots.first;
    final x = mainSpot.x;
    final values = <String, double>{};
    for (final s in series) {
      final nearest = _nearestSpot(s.spots, x);
      if (nearest != null) {
        values[s.label] = nearest.y;
      }
    }
    final localPos = event.localPosition ?? Offset.zero;
    setState(() {
      _tooltip = _TooltipData(time: x, values: values, position: localPos);
    });
  }

  FlSpot? _nearestSpot(List<FlSpot> spots, double targetX) {
    if (spots.isEmpty) {
      return null;
    }
    // spots 依 x 遞增，使用二分搜尋加速（大量點時避免 O(n)）
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

class _Series {
  const _Series({
    required this.label,
    required this.color,
    required this.spots,
  });

  final String label;
  final Color color;
  final List<FlSpot> spots;
}

class _TooltipData {
  _TooltipData({
    required this.time,
    required this.values,
    required this.position,
  });

  final double time;
  final Map<String, double> values;
  final Offset position;
}

class _BrushRect {
  const _BrushRect({required this.left, required this.width});
  final double left;
  final double width;
}

class _YHeightChartData {
  _YHeightChartData({
    required this.series,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.paddingY,
    required this.yInterval,
    required this.length,
  });

  final List<_Series> series;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double paddingY;
  final double yInterval;
  final int length;

  bool get hasEnoughPoints => length >= 2;

  _YHeightChartData applyView(RangeValues? view) {
    if (view == null || view.end - view.start <= 0) {
      return this;
    }
    final filteredSeries = series
        .map(
          (s) => _Series(
            label: s.label,
            color: s.color,
            spots: s.spots
                .where((p) => p.x >= view.start && p.x <= view.end)
                .toList(),
          ),
        )
        .toList();
    final allY = filteredSeries.expand((s) => s.spots.map((p) => p.y)).toList();
    if (allY.isEmpty) {
      return this;
    }
    final minY = allY.reduce(math.min);
    final maxY = allY.reduce(math.max);
    final padding = (maxY - minY) * 0.1;
    return _YHeightChartData(
      series: filteredSeries,
      minX: view.start,
      maxX: view.end,
      minY: minY,
      maxY: maxY,
      paddingY: padding,
      yInterval: yInterval,
      length: filteredSeries.fold<int>(0, (sum, s) => sum + s.spots.length),
    );
  }

  factory _YHeightChartData.fromResponse(
    YHeightDiffResponse response,
    DashboardAccentColors accent, {
    required int maxPoints,
    required HeightUnit unit,
    required bool showDiff,
  }) {
    final yScale = unit.yScale;
    // 直接採用絕對高度輸出，不再平移 baseline，確保圖上值與原始資料一致。
    final spots = _buildSpots(
      response.timeSeconds,
      response.left,
      maxPoints: maxPoints,
      yScale: yScale,
    );
    if (spots.length < 2) {
      return _YHeightChartData(
        series: const [],
        minX: 0,
        maxX: 0,
        minY: 0,
        maxY: 0,
        paddingY: 0,
        yInterval: 1,
        length: spots.length,
      );
    }

    final series = [
      _Series(label: 'Left', color: accent.success, spots: spots),
      _Series(
        label: 'Right',
        color: accent.warning,
        spots: _buildSpots(
          response.timeSeconds,
          response.right,
          maxPoints: maxPoints,
          yScale: yScale,
        ),
      ),
      if (showDiff)
        _Series(
          label: 'Diff (L-R)',
          color: accent.danger,
          spots: _buildSpots(
            response.timeSeconds,
            response.diff,
            maxPoints: maxPoints,
            yScale: yScale,
          ),
        ),
    ];

    var minY = series.first.spots.first.y;
    var maxY = minY;
    for (final s in series) {
      for (final point in s.spots) {
        final y = point.y;
        if (y < minY) {
          minY = y;
        }
        if (y > maxY) {
          maxY = y;
        }
      }
    }
    final span = (maxY - minY).abs();
    // 當曲線幾乎是水平線時，給一個「合理」的最小 padding，避免整張圖看起來貼邊。
    // 這裡用 5cm 當作最小 padding（m/cm 皆一致）。
    final paddingY = span < 1e-6
        ? (unit == HeightUnit.cm ? 5.0 : 0.05)
        : span * 0.1;

    // 自動選擇漂亮的刻度間距，避免 range 很大時左側刻度文字重疊。
    final yInterval = _gridInterval(
      minY - paddingY,
      maxY + paddingY,
      fallback: unit == HeightUnit.cm ? 1 : 0.01,
      // 讓高度軸有更多刻度(預設10)
      targetLines: 10,
    );

    return _YHeightChartData(
      series: series,
      minX: response.timeSeconds.first,
      maxX: response.timeSeconds.isNotEmpty
          ? response.timeSeconds.last
          : series.first.spots.last.x,
      minY: minY,
      maxY: maxY,
      paddingY: paddingY,
      yInterval: yInterval,
      length: series.isEmpty ? 0 : series.first.spots.length,
    );
  }
}

/// 將資料轉換為 FL Chart 的 points，並依 maxPoints 下採樣。
List<FlSpot> _buildSpots(
  List<double> xs,
  List<double> ys, {
  required int maxPoints,
  double yScale = 1,
  double yOffset = 0,
}) {
  final length = math.min(xs.length, ys.length);
  if (length == 0) {
    return const <FlSpot>[];
  }
  final step = math.max(1, (length / maxPoints).ceil());
  final spots = <FlSpot>[];
  for (var i = 0; i < length; i += step) {
    final x = xs[i];
    final y = (ys[i] - yOffset) * yScale;
    if (x.isFinite && y.isFinite) {
      spots.add(FlSpot(x, y));
    }
  }
  if ((length - 1) % step != 0) {
    final x = xs[length - 1];
    final y = (ys[length - 1] - yOffset) * yScale;
    if (x.isFinite && y.isFinite) {
      spots.add(FlSpot(x, y));
    }
  }
  return spots;
}

/// 依據資料範圍自動選擇「漂亮」的刻度間距（1/2/5/10 * 10^n）。
///
/// 目的：
/// - 避免 range 很大時刻度太密，左側文字重疊（你截圖那種情況）。
/// - 在 range 很小時也能維持可讀性。
double _gridInterval(
  double min,
  double max, {
  required double fallback,
  int targetLines = 6,
}) {
  if (!min.isFinite || !max.isFinite) {
    return fallback;
  }
  final span = (max - min).abs();
  if (span <= 0 || !span.isFinite) {
    return fallback;
  }
  final safeTarget = targetLines <= 0 ? 6 : targetLines;
  final raw = span / safeTarget;
  if (raw <= 0 || !raw.isFinite) {
    return fallback;
  }
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
  final normalized = raw / magnitude;
  double interval;
  if (normalized < 1.5) {
    interval = 1;
  } else if (normalized < 3) {
    interval = 2;
  } else if (normalized < 7) {
    interval = 5;
  } else {
    interval = 10;
  }
  final result = interval * magnitude.toDouble();
  if (!result.isFinite || result <= 0) {
    return fallback;
  }
  // fallback 同時扮演「最小可接受刻度」：
  // - cm 以整數顯示，interval < 1 會導致左側標籤重複
  // - m 以小數兩位顯示，interval < 0.01 同樣會重複
  return result < fallback ? fallback : result;
}

double _floorToInterval(double value, double interval) {
  if (!value.isFinite || !interval.isFinite || interval <= 0) {
    return value;
  }
  return (value / interval).floorToDouble() * interval;
}

double _ceilToInterval(double value, double interval) {
  if (!value.isFinite || !interval.isFinite || interval <= 0) {
    return value;
  }
  return (value / interval).ceilToDouble() * interval;
}

/// 將 FlSpots 依 limit 再次下採樣，避免展示過多 sample。
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
