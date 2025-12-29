import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/chart_pan_shortcuts.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';

/// 提供全局 session 趨勢圖，搭配縮放與圈數點選互動。
class SessionOverviewChart extends ConsumerStatefulWidget {
  const SessionOverviewChart({
    required this.laps,
    super.key,
    this.onLapFocusRequested,
  });

  final List<LapSummary> laps;
  final VoidCallback? onLapFocusRequested;

  @override
  ConsumerState<SessionOverviewChart> createState() =>
      _SessionOverviewChartState();
}

class _SessionOverviewChartState extends ConsumerState<SessionOverviewChart> {
  static const double _leftTitlesReservedSize = 48;
  static const double _bottomTitlesReservedSize = 28;
  static const double _minSelectionPx = 18;

  int? _hoverLapIndex;
  double? _brushStartDx;
  double? _brushEndDx;
  Size _chartSize = Size.zero;

  double? _zoomMinX;
  double? _zoomMaxX;

  // 快取目前顯示中的 viewport，讓框選縮放可以把像素轉回資料座標。
  double _viewMinX = 0;
  double _viewMaxX = 1;
  double _fullMinX = 0;
  double _fullMaxX = 1;

  bool get _isXZoomed => _zoomMinX != null || _zoomMaxX != null;

  @override
  Widget build(BuildContext context) {
    if (widget.laps.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.colorScheme;
    final isDark = context.isDark;
    final accent = DashboardAccentColors.of(context);
    // 以 lapIndex 排序，避免 API 回傳順序造成折線錯位。
    final sortedLaps = [...widget.laps]
      ..sort((a, b) => a.lapIndex.compareTo(b.lapIndex));

    final selectedLapIndex = ref.watch(selectedLapIndexProvider);
    // 滑鼠 hover 優先顯示，其次才是鎖定圈數。
    final highlightLapIndex = _hoverLapIndex ?? selectedLapIndex;
    final selectedIndex = highlightLapIndex == null
        ? -1
        : sortedLaps.indexWhere((lap) => lap.lapIndex == highlightLapIndex);

    final spots = [
      for (final lap in sortedLaps)
        FlSpot(lap.lapIndex.toDouble(), lap.totalDurationSeconds),
    ];

    final fullMinX = sortedLaps.first.lapIndex.toDouble();
    final fullMaxX = sortedLaps.last.lapIndex.toDouble();
    _fullMinX = fullMinX;
    _fullMaxX = fullMaxX;

    final minX = (_zoomMinX ?? fullMinX).clamp(fullMinX, fullMaxX).toDouble();
    final maxX = (_zoomMaxX ?? fullMaxX).clamp(fullMinX, fullMaxX).toDouble();

    final visibleLaps = sortedLaps
        .where((lap) {
          final x = lap.lapIndex.toDouble();
          return x >= minX && x <= maxX;
        })
        .toList(growable: false);

    final durations = (visibleLaps.isEmpty ? sortedLaps : visibleLaps)
        .map((lap) => lap.totalDurationSeconds)
        .toList(growable: false);
    final minDuration = durations.reduce(
      (value, element) => element < value ? element : value,
    );
    final maxDuration = durations.reduce(
      (value, element) => element > value ? element : value,
    );
    final padding = ((maxDuration - minDuration).abs() * 0.2)
        .clamp(0.5, 4.0)
        .toDouble();
    // 動態加上 20% padding，讓折線在視覺上保留空間。
    final autoMinY = (minDuration - padding)
        .clamp(0, double.infinity)
        .toDouble();
    final autoMaxY = maxDuration + padding;

    final minY = autoMinY.clamp(0, double.infinity).toDouble();
    final maxY = autoMaxY;

    // 當圈數較多時提高間距，避免 x 軸標籤重疊。
    final visibleCount = (maxX - minX).abs();
    final bottomInterval = (visibleCount > 12 ? 2 : 1).toDouble();

    // 更新目前 viewport 快取（給框選縮放用）。
    _viewMinX = minX;
    _viewMaxX = maxX;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                        'Session 全局趨勢',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '點選資料點即可鎖定圈數；拖曳框選可放大',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: _isXZoomed ? _resetZoom : null,
                        icon: const Icon(Icons.restart_alt, size: 16),
                        label: const Text('重置縮放'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (selectedLapIndex != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text('目前圈數：Lap $selectedLapIndex')),
              ),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 280,
                color: colors.onSurface.withValues(alpha: isDark ? 0.02 : 0.01),
                child: ChartPanShortcuts(
                  onArrow: _handleArrow,
                  onHold: _handleArrowHold,
                  onEscape: () {
                    // Esc：清掉框選狀態與 hover。
                    _clearBrush();
                    if (_hoverLapIndex != null) {
                      setState(() => _hoverLapIndex = null);
                    }
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _chartSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      final brush = _buildBrushRect(_chartSize);

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: () {
                          _resetZoom();
                          _clearBrush();
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
                            setState(() => _brushEndDx = event.localPosition.dx);
                          },
                          onPointerUp: (event) {
                            _tryApplyBrushZoom();
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRect(
                                child: LineChart(
                                  LineChartData(
                            minX: minX,
                            maxX: maxX,
                            minY: minY,
                            maxY: maxY,
                            clipData: const FlClipData.all(),
                            gridData: FlGridData(
                              drawHorizontalLine: true,
                              drawVerticalLine: false, // 移除垂直線，減少雜亂感
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.05),
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
                                  reservedSize: _leftTitlesReservedSize,
                                  interval: _computeYInterval(minY, maxY),
                                  getTitlesWidget: (value, meta) => Text(
                                    '${value.toStringAsFixed(0)} s',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: _bottomTitlesReservedSize,
                                  interval: bottomInterval,
                                  getTitlesWidget: (value, meta) {
                                    final lapValue = value.round();
                                    final isWhole =
                                        (value - lapValue).abs() < 0.01;
                                    if (!isWhole) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      'Lap $lapValue',
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                fitInsideVertically: true,
                                fitInsideHorizontally: true,
                                tooltipMargin: 12,
                                getTooltipColor: (_) =>
                                    isDark ? const Color(0xFF111111) : Colors.black.withValues(alpha: 0.85),
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final lap = spot.x.toInt();
                                    final duration = spot.y;
                                    return LineTooltipItem(
                                      'Lap $lap\n${duration.toStringAsFixed(2)} 秒',
                                      const TextStyle(color: Colors.white),
                                    );
                                  }).toList();
                                },
                              ),
                              touchCallback: _handleTouch,
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: accent.success,
                                barWidth: 2.4, // 稍微調細一點
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      accent.success.withValues(alpha: isDark ? 0.20 : 0.08),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (spot, percent, barData, index) {
                                        final isSelected =
                                            index == selectedIndex;
                                        // 需求：亮色用黑點、暗色用白點。
                                        // 使用 onSurface 剛好符合（light=黑 / dark=白）。
                                        final dotFill = isSelected
                                            ? colors.onSurface
                                            : colors.onSurface.withValues(
                                                alpha: 0.9,
                                              );
                                        return FlDotCirclePainter(
                                          radius: isSelected ? 4.5 : 3.5,
                                          color: dotFill,
                                          strokeWidth: isSelected ? 2.5 : 1.2,
                                          strokeColor: isSelected
                                              ? accent.success
                                              : (isDark 
                                                  ? colors.onSurface.withValues(alpha: 0.12)
                                                  : accent.success.withValues(alpha: 0.5)),
                                        );
                                      },
                                ),
                                showingIndicators: selectedIndex >= 0
                                    ? [selectedIndex]
                                    : const [],
                              ),
                            ],
                                  ),
                                ),
                              ),
                              if (brush != null)
                                Positioned(
                                  left: brush.left,
                                  top: 0,
                                  width: brush.width,
                                  height: _chartSize.height,
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: accent.success.withValues(alpha: 0.10),
                                        border: Border.all(
                                          color: accent.success.withValues(alpha: 0.55),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleArrow(int step) {
    // 只在 X 軸有縮放時允許左右平移，避免在全域視窗下造成困惑。
    if (!_isXZoomed) {
      return;
    }
    _panZoomWindow(step);
  }

  void _handleArrowHold(int step, Duration dt) {
    if (!_isXZoomed) {
      return;
    }
    _panZoomWindowHold(step, dt);
  }

  void _panZoomWindow(int step) {
    final span = (_viewMaxX - _viewMinX).abs();
    if (span <= 0) {
      return;
    }
    // 一次平移視窗寬度的 12%。
    final delta = span * 0.12 * step;
    final nextMin =
        (_viewMinX + delta).clamp(_fullMinX, _fullMaxX - span).toDouble();
    final nextMax = (nextMin + span).clamp(_fullMinX + span, _fullMaxX).toDouble();
    setState(() {
      _zoomMinX = nextMin;
      _zoomMaxX = nextMax;
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
    const speedWindowsPerSecond = 0.85;
    final delta = span * speedWindowsPerSecond * dtSeconds * step;
    final nextMin =
        (_viewMinX + delta).clamp(_fullMinX, _fullMaxX - span).toDouble();
    final nextMax = (nextMin + span).clamp(_fullMinX + span, _fullMaxX).toDouble();
    setState(() {
      _zoomMinX = nextMin;
      _zoomMaxX = nextMax;
      _brushStartDx = null;
      _brushEndDx = null;
    });
  }

  /// 處理圖表互動，統一更新 hover 與鎖定的圈數。
  void _handleTouch(FlTouchEvent event, LineTouchResponse? response) {
    final spots = response?.lineBarSpots;
    if (spots == null || spots.isEmpty) {
      // 當前沒有觸點資料時，視情況重置 hover。
      if (event is FlTapUpEvent ||
          event is FlTapCancelEvent ||
          event is FlPanEndEvent ||
          event is FlPanCancelEvent ||
          event is FlPointerExitEvent ||
          event is FlPointerEnterEvent) {
        if (_hoverLapIndex != null) {
          setState(() => _hoverLapIndex = null);
        }
      }
      return;
    }

    // FL Chart 只會提供一組 spots，取第一個即可代表當前圈數。
    final lapIndex = spots.first.x.round();

    if (event is FlPanDownEvent ||
        event is FlPanStartEvent ||
        event is FlPanUpdateEvent ||
        event is FlTapDownEvent ||
        event is FlPointerHoverEvent ||
        event is FlLongPressStart ||
        event is FlLongPressMoveUpdate) {
      if (_hoverLapIndex != lapIndex) {
        setState(() => _hoverLapIndex = lapIndex);
      }
      return;
    }

    if (event is FlTapUpEvent ||
        event is FlPanEndEvent ||
        event is FlLongPressEnd) {
      // 放開手勢後，鎖定圈數並通知外部聚焦。
      if (_hoverLapIndex != null) {
        setState(() => _hoverLapIndex = null);
      }
      final notifier = ref.read(selectedLapIndexProvider.notifier);
      final current = ref.read(selectedLapIndexProvider);
      if (current != lapIndex) {
        notifier.select(lapIndex);
        widget.onLapFocusRequested?.call();
      } else {
        widget.onLapFocusRequested?.call();
      }
      return;
    }

    if (event is FlTapCancelEvent || event is FlPanCancelEvent) {
      // 取消事件需確保狀態回復，以免留著 ghost highlight。
      if (_hoverLapIndex != null) {
        setState(() => _hoverLapIndex = null);
      }
    }
  }

  void _resetZoom() {
    setState(() {
      _zoomMinX = null;
      _zoomMaxX = null;
      _brushStartDx = null;
      _brushEndDx = null;
    });
  }

  _BrushRect? _buildBrushRect(Size size) {
    final start = _brushStartDx;
    final end = _brushEndDx;
    if (start == null || end == null) {
      return null;
    }
    final left = math.max(0.0, math.min(start, end));
    final right = math.min(size.width, math.max(start, end));
    if (right - left < _minSelectionPx) {
      return null;
    }
    return _BrushRect(left: left, width: right - left);
  }

  void _tryApplyBrushZoom() {
    final size = _chartSize;
    final brush = _buildBrushRect(size);
    if (brush == null || size.width <= 0) {
      _clearBrush();
      return;
    }

    final span = (_viewMaxX - _viewMinX).abs();
    final leftPct = (brush.left / size.width).clamp(0.0, 1.0);
    final rightPct =
        ((brush.left + brush.width) / size.width).clamp(0.0, 1.0);
    final rawMinX = _viewMinX + leftPct * span;
    final rawMaxX = _viewMinX + rightPct * span;
    final nextMinX = rawMinX.floorToDouble().clamp(_fullMinX, _fullMaxX);
    final nextMaxX = rawMaxX.ceilToDouble().clamp(_fullMinX, _fullMaxX);
    if ((nextMaxX - nextMinX).abs() < 1) {
      _clearBrush();
      return;
    }

    setState(() {
      _zoomMinX = nextMinX;
      _zoomMaxX = nextMaxX;
      _brushStartDx = null;
      _brushEndDx = null;
    });
  }

  void _clearBrush() {
    if (_brushStartDx == null && _brushEndDx == null) {
      return;
    }
    setState(() {
      _brushStartDx = null;
      _brushEndDx = null;
    });
  }


  double _computeYInterval(double min, double max) {
    final delta = (max - min).abs();
    if (delta <= 0) return 1.0;
    // 目標約 8 條水平線
    final raw = delta / 8;
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
    return interval * magnitude.toDouble();
  }
}

class _BrushRect {
  const _BrushRect({required this.left, required this.width});
  final double left;
  final double width;
}
