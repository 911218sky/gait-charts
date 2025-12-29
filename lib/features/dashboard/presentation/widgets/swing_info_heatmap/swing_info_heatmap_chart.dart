import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// Swing 熱圖：
/// - 以 swing% 作為底色
/// - 互動式 Hover 顯示完整資訊
/// - 圓角方塊風格，更有現代感
class SwingInfoHeatmapChart extends StatefulWidget {
  const SwingInfoHeatmapChart({
    required this.response,
    this.vminPct,
    this.vmaxPct,
    super.key,
  });

  final SwingInfoHeatmapResponse response;
  final double? vminPct;
  final double? vmaxPct;

  @override
  State<SwingInfoHeatmapChart> createState() => _SwingInfoHeatmapChartState();
}

class _SwingInfoHeatmapChartState extends State<SwingInfoHeatmapChart> {
  Offset? _localPos;
  final ScrollController _horizontalController = ScrollController();

  void _onHover(PointerEvent event) {
    setState(() {
      _localPos = event.localPosition;
    });
  }

  void _onExit(PointerEvent event) {
    setState(() {
      _localPos = null;
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _dragToScroll(DragUpdateDetails details) {
    if (!_horizontalController.hasClients) return;
    final pos = _horizontalController.position;
    final next = (_horizontalController.offset - details.delta.dx).clamp(
      0.0,
      pos.maxScrollExtent,
    );
    if (next == _horizontalController.offset) return;
    _horizontalController.jumpTo(next);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final palette = DashboardHeatmapPalette.of(context);
    final response = widget.response;

    // 背景使用 swing% 色階
    final min = widget.vminPct ?? response.pctMin;
    final max = widget.vmaxPct ?? response.pctMax;

    final scale = _HeatmapColorScale(min: min, max: max, palette: palette);

    final cols = response.minutesCount;
    // 分鐘越多越寬，並提供水平捲動。稍微加大每格寬度以容納圓角與間距。
    final cellWidth = cols <= 0 ? 24.0 : math.max(64.0, 920.0 / cols);
    final chartWidth = cols * cellWidth;
    const chartHeight = 200.0; // 兩列，高度足夠容納內容

    // 計算 hover
    int? hoverRow;
    int? hoverCol;
    double? hoverPct;
    double? hoverSec;
    int? hoverMinute;

    if (_localPos != null && cols > 0) {
      const rows = 2;
      const cellH = chartHeight / rows;
      final cellW = chartWidth / cols;

      final r = (_localPos!.dy / cellH).floor();
      final c = (_localPos!.dx / cellW).floor();

      if (r >= 0 && r < rows && c >= 0 && c < cols) {
        hoverRow = r;
        hoverCol = c;
        hoverMinute = response.minutes[c];

        final pctRow = r < response.swingPct.length
            ? response.swingPct[r]
            : const <double?>[];
        final secRow = r < response.swingSeconds.length
            ? response.swingSeconds[r]
            : const <double?>[];

        if (c < pctRow.length) hoverPct = pctRow[c];
        if (c < secRow.length) hoverSec = secRow[c];
      }
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Swing percentage (per minute)',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _LegendBar(
              label: 'Swing (% of stride)',
              min: min,
              max: max,
              palette: palette,
            ),
            const SizedBox(height: 20),
            ScrollConfiguration(
              behavior: const _HeatmapScrollBehavior(),
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: !context.isMobile,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 70,
                            child: Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _RowLabel(text: 'Left'),
                                  SizedBox(height: 56),
                                  _RowLabel(text: 'Right'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            // 手機上用「左右拖曳」直覺捲動（有些平台/容器下，
                            // 直接 drag ScrollView 會被其他手勢搶走）。
                            onHorizontalDragUpdate:
                                context.isMobile ? _dragToScroll : null,
                            behavior: HitTestBehavior.opaque,
                            child: MouseRegion(
                              onHover: _onHover,
                              onExit: _onExit,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // 避免在 build 內 addPostFrameCallback + setState 造成不必要的 rebuild。
                                  // 這裡尺寸是已知的：直接用 chartWidth/chartHeight 即可。
                                  RepaintBoundary(
                                    child: CustomPaint(
                                      size: Size(chartWidth, chartHeight),
                                      painter: _SwingHeatmapPainter(
                                        swingPct: response.swingPct,
                                        swingSeconds: response.swingSeconds,
                                        minutes: response.minutes,
                                        scale: scale,
                                        emptyColor: context
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.1),
                                        textColor: context.colorScheme.onSurface,
                                        hoverRow: hoverRow,
                                        hoverCol: hoverCol,
                                      ),
                                    ),
                                  ),
                                  // Tooltip
                                  if (_localPos != null &&
                                      hoverRow != null &&
                                      hoverMinute != null)
                                    Positioned(
                                      left: _localPos!.dx + 16,
                                      top: _localPos!.dy + 16,
                                      child: IgnorePointer(
                                        child: DashboardGlassTooltip(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Minute $hoverMinute',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: context
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withValues(alpha: 0.75),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                hoverRow == 0
                                                    ? 'Left Leg'
                                                    : 'Right Leg',
                                                style: TextStyle(
                                                  color: context
                                                      .colorScheme
                                                      .onSurface,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              _TooltipRow(
                                                label: 'Swing %',
                                                value: hoverPct != null
                                                    ? '${hoverPct.toStringAsFixed(1)}%'
                                                    : '-',
                                              ),
                                              const SizedBox(height: 2),
                                              _TooltipRow(
                                                label: 'Duration',
                                                value: hoverSec != null
                                                    ? '${hoverSec.toStringAsFixed(2)}s'
                                                    : '-',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // X 軸標籤 (對齊格子中心)
                      if (response.minutes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 82,
                          ), // Label width (70) + gap (12)
                          child: SizedBox(
                            width: chartWidth,
                            height: 20,
                            child: _MinuteAxis(
                              minutes: response.minutes,
                              cellWidth: cellWidth,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                context.isMobile ? '左右滑動查看更多分鐘。' : 'Hover 查看詳細數據。可水平捲動。',
                style: textTheme.bodySmall?.copyWith(
                  // 亮色模式提高對比，避免提示文字過淡看不清楚。
                  color: context.colorScheme.onSurface.withValues(
                    alpha: context.isDark ? 0.5 : 0.72,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapScrollBehavior extends MaterialScrollBehavior {
  const _HeatmapScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class _MinuteAxis extends StatelessWidget {
  const _MinuteAxis({required this.minutes, required this.cellWidth});

  final List<int> minutes;
  final double cellWidth;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    final isDark = context.isDark;
    // 亮色模式提高對比；暗色模式維持更柔和的輔助文字。
    final labelColor = isDark
        ? colors.onSurface.withValues(alpha: 0.55)
        : colors.onSurfaceVariant.withValues(alpha: 0.80);
    return Stack(
      children: List.generate(minutes.length, (index) {
        // 每隔幾分鐘顯示一次，避免擁擠
        // 但因為現在格子很寬，幾乎可以全部顯示，或視寬度抽樣
        final show = cellWidth > 50 || index % 2 == 0;
        if (!show) return const SizedBox.shrink();

        return Positioned(
          left: index * cellWidth,
          width: cellWidth,
          child: Center(
            child: Text(
              'Min ${minutes[index]}',
              style: textTheme.labelSmall?.copyWith(
                color: labelColor,
                fontSize: 10,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TooltipRow extends StatelessWidget {
  const _TooltipRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFeatures: const [ui.FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colors = context.colorScheme;
    return Container(
      height: 80, // 約等於 Painter 裡的一行高度減去間距
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: textTheme.titleSmall?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.8),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _LegendBar extends StatelessWidget {
  const _LegendBar({
    required this.label,
    required this.min,
    required this.max,
    required this.palette,
  });

  final String label;
  final double? min;
  final double? max;
  final DashboardHeatmapPalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = palette.colors;
    final effectiveMin = min;
    final effectiveMax = max;
    final rangeLabel = (effectiveMin == null || effectiveMax == null)
        ? '—'
        : '${effectiveMin.toStringAsFixed(2)} → ${effectiveMax.toStringAsFixed(2)}';

    final labelText = Text(
      '$label  |  $rangeLabel',
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      maxLines: context.isMobile ? 2 : 1,
      overflow: TextOverflow.ellipsis,
    );

    final bar = Container(
      width: context.isMobile ? double.infinity : 180,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(colors: colors),
      ),
    );

    // 手機：兩排（文字 + 色條）避免 Row overflow。
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labelText,
          const SizedBox(height: 10),
          bar,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: labelText),
        const SizedBox(width: 16),
        bar,
      ],
    );
  }
}

class _SwingHeatmapPainter extends CustomPainter {
  _SwingHeatmapPainter({
    required this.swingPct,
    required this.swingSeconds,
    required this.minutes,
    required this.scale,
    required this.emptyColor,
    required this.textColor,
    this.hoverRow,
    this.hoverCol,
  });

  final List<List<double?>> swingPct;
  final List<List<double?>> swingSeconds;
  final List<int> minutes;
  final _HeatmapColorScale scale;
  final Color emptyColor;
  final Color textColor;
  final int? hoverRow;
  final int? hoverCol;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (minutes.isEmpty) return;

    const rows = 2;
    final cols = minutes.length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // 設定格子間距與圓角
    const gap = 6.0;
    const radius = 6.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var r = 0; r < rows; r++) {
      final pctRow = r < swingPct.length ? swingPct[r] : const <double?>[];
      final secRow =
          r < swingSeconds.length ? swingSeconds[r] : const <double?>[];

      for (var c = 0; c < cols; c++) {
        final pct = c < pctRow.length ? pctRow[c] : null;
        final sec = c < secRow.length ? secRow[c] : null;

        // 計算實際繪製區域
        final rect = Rect.fromLTWH(
          c * cellW + gap / 2,
          r * cellH + gap / 2,
          cellW - gap,
          cellH - gap,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));

        final pctOk = pct != null && pct.isFinite;
        final secOk = sec != null && sec.isFinite;
        final color = pctOk ? scale.colorFor(pct) : null;

        // 1. 繪製背景 (圓角方塊)
        canvas.drawRRect(
          rrect,
          Paint()..color = color ?? emptyColor,
        );

        // 2. Hover 效果
        if (r == hoverRow && c == hoverCol) {
          // 亮框
          canvas.drawRRect(
            rrect,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          // 微微提亮覆蓋
          canvas.drawRRect(
            rrect,
            Paint()..color = Colors.white.withValues(alpha: 0.1),
          );
        }

        // 3. 繪製文字 (pct 大, sec 小)
        final pctLabel = pctOk ? '${pct.toStringAsFixed(1)}%' : 'n/a';
        final secLabel = secOk ? '${sec.toStringAsFixed(2)}s' : '';

        // 判斷文字顏色
        final effectiveTextColor = _pickReadableTextColor(
          background: color ?? emptyColor,
          fallback: textColor,
        );

        final textSpan = TextSpan(
          children: [
            // Swing % (上方大字)
            TextSpan(
              text: pctLabel,
              style: TextStyle(
                color: effectiveTextColor,
                fontSize: cellW < 60 ? 12 : 15,
                fontWeight: FontWeight.w700,
                height: 1.4,
                shadows: const [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black26,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
            if (secLabel.isNotEmpty) ...[
              const TextSpan(text: '\n'),
              TextSpan(
                text: secLabel,
                style: TextStyle(
                  color: effectiveTextColor.withValues(alpha: 0.85),
                  fontSize: cellW < 60 ? 10 : 11,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ],
        );

        textPainter.text = textSpan;
        textPainter.textAlign = TextAlign.center;
        textPainter.layout(maxWidth: rect.width - 4);
        
        // 垂直置中
        final dx = rect.left + (rect.width - textPainter.width) / 2;
        final dy = rect.top + (rect.height - textPainter.height) / 2;
        textPainter.paint(canvas, Offset(dx, dy));
      }
    }
  }

  Color _pickReadableTextColor({
    required Color background,
    required Color fallback,
  }) {
    final lum = background.computeLuminance();
    if (lum < 0.4) return Colors.white.withValues(alpha: 0.95);
    if (lum > 0.7) return Colors.black.withValues(alpha: 0.85);
    return fallback;
  }

  @override
  bool shouldRepaint(covariant _SwingHeatmapPainter oldDelegate) {
    return oldDelegate.swingPct != swingPct ||
        oldDelegate.swingSeconds != swingSeconds ||
        oldDelegate.minutes != minutes ||
        oldDelegate.scale != scale ||
        oldDelegate.emptyColor != emptyColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.hoverRow != hoverRow ||
        oldDelegate.hoverCol != hoverCol;
  }
}

class _HeatmapColorScale {
  const _HeatmapColorScale({
    required this.min,
    required this.max,
    required this.palette,
  });

  final double? min;
  final double? max;
  final DashboardHeatmapPalette palette;

  Color? colorFor(double value) {
    if (min == null || max == null) return null;
    final domain = max! - min!;
    if (domain.abs() < 1e-6) return palette.colorAt(0.5);
    final t = ((value - min!) / domain).clamp(0.0, 1.0);
    return palette.colorAt(t);
  }
}
