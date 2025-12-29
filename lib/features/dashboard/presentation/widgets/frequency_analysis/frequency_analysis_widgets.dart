import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/app_tooltip.dart';
import 'package:gait_charts/core/widgets/chart_pan_shortcuts.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';

/// 區段標題元件，左側帶有漸層色條裝飾
class FrequencySectionHeader extends StatelessWidget {
  const FrequencySectionHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
    super.key,
  });

  final String title;
  final String subtitle;
  final DashboardAccentColors accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 32,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.success, accent.warning],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 頻率分析區塊的空狀態顯示，用於資料尚未載入或無資料時
class FrequencyEmptyState extends StatelessWidget {
  const FrequencyEmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        color: colors.surface,
      ),
      child: Text(
        message,
        style: context.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}

/// 峰值摘要列表，以 Chip 形式顯示各頻率系列的前幾個主要峰值
class PeakSummaryList extends StatelessWidget {
  const PeakSummaryList({required this.entries, super.key});

  final List<PeakSummaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final chips = <Widget>[];
    for (final entry in entries) {
      if (entry.peaks.isEmpty) {
        continue;
      }
      // 只顯示前 3 個峰值，避免資訊過多
      final highlights = entry.peaks.take(3).toList();
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12)),
            color: colors.onSurface.withValues(alpha: isDark ? 0.02 : 0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.label,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final peak in highlights)
                Text(
                  '${peak.freq.toStringAsFixed(2)} Hz / '
                  '${peak.db.toStringAsFixed(1)} dB',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peak 摘要',
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: chips),
      ],
    );
  }
}

/// 頻率圖表的單一資料系列，包含 X/Y 軸數據及峰值標記
class FrequencySeries {
  FrequencySeries({
    required this.label,
    required this.xValues,
    required this.yValues,
    required this.color,
    required this.peaks,
  });

  final String label;

  /// X 軸數值 (通常為頻率 Hz)
  final List<double> xValues;

  /// Y 軸數值 (通常為振幅 dB)
  final List<double> yValues;

  /// 該系列中偵測到的峰值點
  final List<FrequencyPeak> peaks;
  final Color color;

  bool get hasData => xValues.isNotEmpty && yValues.isNotEmpty;
}

/// 頻譜峰值資料，記錄頻率 (Hz) 與振幅 (dB)
class FrequencyPeak {
  const FrequencyPeak({required this.freq, required this.db});

  final double freq;
  final double db;
}

/// 峰值摘要項目，用於 [PeakSummaryList] 顯示
class PeakSummaryEntry {
  const PeakSummaryEntry({
    required this.label,
    required this.color,
    required this.peaks,
  });

  final String label;
  final Color color;
  final List<FrequencyPeak> peaks;
}

/// 頻率折線圖元件，支援多系列資料與峰值標記
///
/// 自動進行降採樣以維持效能，同時保留峰值點位以確保重要特徵不遺失
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

  /// 最大取樣點數，超過此數量會進行降採樣
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

    final validSeries = widget.series
        .where((entry) => entry.hasData)
        .toList(growable: false);
    if (validSeries.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child:           Text(
            widget.emptyLabel,
            style: context.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
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
      // 建立頻譜曲線點位，優先保留峰值頻率
      final spots = buildFrequencySpots(
        entry.xValues,
        entry.yValues,
        maxPoints: widget.maxSamples,
        priorityX: entry.peaks.map((peak) => peak.freq),
      );
      if (spots.isEmpty) {
        continue;
      }
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

      // 為峰值點建立獨立的標記點圖層
      if (entry.peaks.isNotEmpty) {
        final peakSpots = entry.peaks
            .map((peak) => FlSpot(peak.freq, peak.db))
            .where((spot) => spot.y.isFinite && spot.x.isFinite)
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
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
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
        child: Center(
          child: Text('無資料', style: TextStyle(color: colors.onSurfaceVariant)),
        ),
      );
    }

    // 為圖表邊界預留適當 padding，避免資料點貼邊
    final yPadding = (maxY - minY).abs() * 0.12;
    final xPadding = (maxX - minX).abs() * 0.02;

    final fullMinX = minX - xPadding;
    final fullMaxX = maxX + xPadding;
    _fullMinX = fullMinX;
    _fullMaxX = fullMaxX;

    final viewMinX = (_zoomMinX ?? fullMinX)
        .clamp(fullMinX, fullMaxX)
        .toDouble();
    final viewMaxX = (_zoomMaxX ?? fullMaxX)
        .clamp(fullMinX, fullMaxX)
        .toDouble();

    var autoMinY = minY - (yPadding == 0 ? 5 : yPadding);
    var autoMaxY = maxY + (yPadding == 0 ? 5 : yPadding);

    // 參考「高度差」：縮放以 X 軸為主，Y 軸保持自動貼合可視範圍。
    if (_isZoomed) {
      var visibleMinY = double.infinity;
      var visibleMaxY = -double.infinity;
      for (final bar in bars) {
        for (final spot in bar.spots) {
          if (spot.x < viewMinX || spot.x > viewMaxX) {
            continue;
          }
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

    // 更新 viewport 快取，讓框選時能把像素座標轉回資料座標。
    _viewMinX = viewMinX;
    _viewMaxX = viewMaxX;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: validSeries
              .map(
                (entry) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: entry.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.label,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 永遠顯示：避免使用者找不到「重置縮放」。
            // 未縮放時禁用按鈕（灰掉但仍在畫面上）。
            FilledButton.tonalIcon(
              onPressed: _isZoomed ? _resetZoom : null,
              icon: const Icon(Icons.restart_alt, size: 16),
              label: const Text('重置縮放'),
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
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 320,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final tooltip = _tooltip;
              final brush = _buildBrushRect(chartSize);
              final tooltipMaxWidth = math.min(180.0, chartSize.width);
              final tooltipMaxHeight = math.min(140.0, chartSize.height);
              final maxTooltipLeft = math.max(
                0.0,
                chartSize.width - tooltipMaxWidth,
              );
              final maxTooltipTop = math.max(
                0.0,
                chartSize.height - tooltipMaxHeight,
              );

              Widget chart = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: _resetZoom,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    if (event.buttons != kPrimaryButton) {
                      return;
                    }
                    setState(() {
                      _tooltip = null;
                      _brushStartDx = event.localPosition.dx;
                      _brushEndDx = event.localPosition.dx;
                    });
                  },
                  onPointerMove: (event) {
                    if (_brushStartDx == null) {
                      return;
                    }
                    setState(() {
                      _brushEndDx = event.localPosition.dx;
                    });
                  },
                  onPointerUp: (event) {
                    final start = _brushStartDx;
                    final end = _brushEndDx;
                    if (start != null && end != null) {
                      final left = math
                          .min(start, end)
                          .clamp(0.0, chartSize.width);
                      final right = math
                          .max(start, end)
                          .clamp(0.0, chartSize.width);
                      if ((right - left) > _minBrushWidthPx) {
                        final span = (_viewMaxX - _viewMinX).abs();
                        final nextMinX =
                            (_viewMinX + (left / chartSize.width) * span)
                                .clamp(_fullMinX, _fullMaxX)
                                .toDouble();
                        final nextMaxX =
                            (_viewMinX + (right / chartSize.width) * span)
                                .clamp(_fullMinX, _fullMaxX)
                                .toDouble();
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
                        child: LineChart(
                          LineChartData(
                            minX: viewMinX,
                            maxX: viewMaxX,
                            minY: viewMinY,
                            maxY: viewMaxY,
                            clipData: const FlClipData.all(),
                            extraLinesData: ExtraLinesData(
                              verticalLines: tooltip == null
                                  ? const []
                                  : [
                                      VerticalLine(
                                        x: tooltip.x,
                                        strokeWidth: 1.2,
                                        color: colors.onSurface.withValues(
                                          alpha: isDark ? 0.35 : 0.45,
                                        ),
                                        dashArray: [6, 6],
                                      ),
                                    ],
                            ),
                            gridData: FlGridData(
                              drawHorizontalLine: true,
                              drawVerticalLine: false, // 移除垂直線讓畫面更清爽
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
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: _leftTitlesReservedSize,
                                  interval: frequencyGridInterval(
                                    viewMinY,
                                    viewMaxY,
                                    fallback: 5,
                                  ),
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toStringAsFixed(0),
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                axisNameSize: _axisNameSize,
                                axisNameWidget: Text(
                                  widget.yLabel,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: _bottomTitlesReservedSize,
                                  interval: frequencyGridInterval(
                                    viewMinX,
                                    viewMaxX,
                                    fallback: 0.5,
                                  ),
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                axisNameSize: _axisNameSize,
                                axisNameWidget: Text(
                                  widget.xLabel,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            lineBarsData: bars,
                            lineTouchData: LineTouchData(
                              handleBuiltInTouches: false,
                              touchSpotThreshold: 18,
                              touchCallback: (event, response) =>
                                  _handleTouch(event, response, labels),
                              touchTooltipData: LineTouchTooltipData(
                                tooltipPadding: EdgeInsets.zero,
                                getTooltipItems: (touchedSpots) => [],
                              ),
                            ),
                          ),
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
                              color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
                            ),
                          ),
                        ),
                      if (tooltip != null)
                        Positioned(
                          left: (tooltip.position.dx - tooltipMaxWidth / 2)
                              .clamp(0.0, maxTooltipLeft)
                              .toDouble(),
                          top: (tooltip.position.dy - 120)
                              .clamp(0.0, maxTooltipTop)
                              .toDouble(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: tooltipMaxWidth,
                              maxHeight: tooltipMaxHeight,
                            ),
                            child: DashboardGlassTooltip(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (tooltip.label.isNotEmpty)
                                    Text(
                                      tooltip.label,
                                      style: context.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  Text(
                                    '${tooltip.x.toStringAsFixed(2)} Hz / '
                                    '${tooltip.y.toStringAsFixed(1)} dB',
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurface.withValues(alpha: 0.82),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );

              chart = ChartPanShortcuts(
                onArrow: _handleArrow,
                onHold: _handleArrowHold,
                onEscape: () {
                  if (_tooltip != null) {
                    setState(() => _tooltip = null);
                  }
                },
                child: chart,
              );

              return chart;
            },
          ),
        ),
      ],
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
    if (_brushStartDx == null || _brushEndDx == null) {
      return null;
    }
    final left = math.max(0.0, math.min(_brushStartDx!, _brushEndDx!));
    final right = math.min(size.width, math.max(_brushStartDx!, _brushEndDx!));
    if (right - left <= 0) {
      return null;
    }
    return _BrushRect(left: left, width: right - left);
  }

  void _handleTouch(
    FlTouchEvent event,
    LineTouchResponse? response,
    Map<LineChartBarData, String> labels,
  ) {
    if (_brushStartDx != null) {
      return;
    }

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

    final mainSpot = spots.firstWhere(
      (spot) => spot.bar.barWidth > 0,
      orElse: () => spots.first,
    );
    final label = labels[mainSpot.bar] ?? '';
    final localPos = event.localPosition ?? Offset.zero;
    setState(() {
      _tooltip = _FrequencyTooltip(
        label: label,
        x: mainSpot.x,
        y: mainSpot.y,
        position: localPos,
      );
    });
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
    // 使用者需求：放大後希望左右鍵是「畫面平移」。
    if (_isZoomed) {
      _panZoomWindow(step);
      return;
    }
    // 未縮放時不做任何事（全域範圍下平移沒有意義，且避免誤解成游標滑動）。
  }

  void _handleArrowHold(int step, Duration dt) {
    if (!_isZoomed) {
      return;
    }
    _panZoomWindowHold(step, dt);
  }

  void _panZoomWindow(int step) {
    final span = (_viewMaxX - _viewMinX).abs();
    if (span <= 0) {
      return;
    }
    // 一次平移視窗寬度的 12%，手感接近「按住鍵盤微移」。
    final delta = span * 0.12 * step;

    final minAllowed = _fullMinX;
    final maxAllowed = _fullMaxX;
    final nextMin = (_viewMinX + delta).clamp(minAllowed, maxAllowed - span);
    final nextMax = (nextMin + span).clamp(minAllowed + span, maxAllowed);

    setState(() {
      _zoomMinX = nextMin.toDouble();
      _zoomMaxX = nextMax.toDouble();
      // 平移視窗時先清掉 tooltip，避免出現「游標不在畫面內」的困惑。
      _tooltip = null;
      _brushStartDx = null;
      _brushEndDx = null;
    });
  }

  void _panZoomWindowHold(int step, Duration dt) {
    final span = (_viewMaxX - _viewMinX).abs();
    if (span <= 0) {
      return;
    }
    final dtSeconds = dt.inMicroseconds / 1e6;
    if (dtSeconds <= 0) {
      return;
    }

    // 平移速度：以「視窗寬度 / 秒」表示，調整後長按手感更順。
    const speedWindowsPerSecond = 0.85;
    final delta = span * speedWindowsPerSecond * dtSeconds * step;

    final minAllowed = _fullMinX;
    final maxAllowed = _fullMaxX;
    final nextMin =
        (_viewMinX + delta).clamp(minAllowed, maxAllowed - span).toDouble();
    final nextMax = (nextMin + span).clamp(minAllowed + span, maxAllowed).toDouble();

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
  const _FrequencyTooltip({
    required this.label,
    required this.x,
    required this.y,
    required this.position,
  });

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

/// 將頻率資料轉換為圖表點位，並進行降採樣以維持效能
///
/// [priorityX] 中指定的 X 值會優先保留，確保峰值等重要特徵不因降採樣而遺失
List<FlSpot> buildFrequencySpots(
  List<double> xs,
  List<double> ys, {
  required int maxPoints,
  Iterable<double> priorityX = const [],
}) {
  final count = math.min(xs.length, ys.length);
  if (count == 0) {
    return <FlSpot>[];
  }
  // 資料點數未超過上限，直接返回所有點
  if (count <= maxPoints) {
    return List<FlSpot>.generate(
      count,
      (index) => FlSpot(xs[index].toDouble(), ys[index].toDouble()),
    );
  }
  // 等間隔降採樣
  final step = (count / maxPoints).ceil();
  final spots = <FlSpot>[];
  for (var i = 0; i < count; i += step) {
    spots.add(FlSpot(xs[i].toDouble(), ys[i].toDouble()));
  }
  // 確保最後一個點被包含
  if (spots.last.x != xs[count - 1]) {
    spots.add(FlSpot(xs[count - 1].toDouble(), ys[count - 1].toDouble()));
  }
  // 補回優先保留的 X 值對應點位 (如峰值頻率)
  final indicesToInclude = priorityX
      .where((value) => value.isFinite)
      .map((value) => closestFrequencyIndex(xs, value))
      .whereType<int>()
      .toSet();
  for (final index in indicesToInclude) {
    final spot = FlSpot(xs[index].toDouble(), ys[index].toDouble());
    final exists = spots.any(
      (existing) =>
          (existing.x - spot.x).abs() < 1e-6 &&
          (existing.y - spot.y).abs() < 1e-6,
    );
    if (!exists) {
      spots.add(spot);
    }
  }
  spots.sort((a, b) => a.x.compareTo(b.x));
  return spots;
}

/// 在頻率陣列中尋找最接近目標值的索引
int? closestFrequencyIndex(List<double> xs, double value) {
  if (xs.isEmpty) {
    return null;
  }
  var bestIndex = 0;
  var bestDelta = (xs[0] - value).abs();
  for (var i = 1; i < xs.length; i++) {
    final delta = (xs[i] - value).abs();
    if (delta < bestDelta) {
      bestDelta = delta;
      bestIndex = i;
      // 提早結束，已經非常接近
      if (bestDelta < 1e-9) {
        break;
      }
    }
  }
  return bestIndex;
}

/// 計算圖表網格線的適當間距
///
/// 根據資料範圍自動選擇 1、2、5、10 系列的「漂亮」間距值
double frequencyGridInterval(
  double min,
  double max, {
  double fallback = 1,
  int targetLines = 8, // 增加預設刻度數量
}) {
  if (!min.isFinite || !max.isFinite) {
    return fallback;
  }
  final span = (max - min).abs();
  if (span <= 0) {
    return fallback;
  }
  // 目標約 targetLines 條網格線
  final raw = span / targetLines;
  if (raw <= 0) {
    return fallback;
  }
  // 計算數量級並正規化
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
  final normalized = raw / magnitude;
  // 選擇 1、2、5、10 中最接近的值
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
  return interval * magnitude.toDouble();
}

/// 頻率系列預設調色盤，藍綠黃粉紫青六色循環
List<Color> frequencySeriesPalette() {
  return const [
    Color(0xFF60A5FA), // 藍
    Color(0xFF34D399), // 綠
    Color(0xFFFBBF24), // 黃
    Color(0xFFF472B6), // 粉
    Color(0xFFA78BFA), // 紫
    Color(0xFF38BDF8), // 青
  ];
}

/// 建立頻率分析選項切換 Chip (如：顯示/隱藏某軸線)
Widget buildFrequencyToggleChip(
  BuildContext context, {
  required String label,
  required bool selected,
  required VoidCallback onTap,
  Color? accentColor,
  String? tooltip,
}) {
  final colors = context.colorScheme;
  final isDark = context.isDark;
  final color = accentColor ?? DashboardAccentColors.of(context).success;
  final chip = FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    labelStyle: TextStyle(
      fontWeight: FontWeight.w600,
      color: selected ? colors.onSurface : colors.onSurfaceVariant,
      letterSpacing: 0.3,
    ),
    backgroundColor: colors.onSurface.withValues(alpha: 0.04),
    // 淺色模式降低填色強度，避免看起來髒/厚；深色維持更明顯的選取層次。
    selectedColor: color.withValues(alpha: isDark ? 0.18 : 0.14),
    side: BorderSide(
      color: selected ? color : colors.onSurface.withValues(alpha: isDark ? 0.18 : 0.12),
      width: 1.2,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    pressElevation: 0,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    clipBehavior: Clip.antiAlias,
    surfaceTintColor: Colors.transparent,
  );
  if (tooltip != null) {
    return AppTooltip(message: tooltip, child: chip);
  }
  return chip;
}

/// 根據系列基色計算峰值標記點的顏色 (提高亮度以突顯)
Color frequencyPeakDotColor(Color base) {
  final hsl = HSLColor.fromColor(base);
  final lighter = hsl.withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0));
  return lighter.toColor();
}
