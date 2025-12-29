import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// 呈現速度熱圖與色階說明。
class SpeedHeatmapChart extends StatelessWidget {
  const SpeedHeatmapChart({
    required this.response,
    this.vmin,
    this.vmax,
    super.key,
  });

  final SpeedHeatmapResponse response;
  final double? vmin;
  final double? vmax;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final heatmapPalette = DashboardHeatmapPalette.of(context);
    final textTheme = context.textTheme;

    // UI 若有手動指定色階，優先使用；否則依資料 min/max。
    final colorMin = vmin ?? response.dataMin;
    final colorMax = vmax ?? response.dataMax;
    final scale = _HeatmapColorScale(
      min: colorMin,
      max: colorMax,
      palette: heatmapPalette,
    );

    final chartHeight = math.max(180.0, response.lapCount * 28.0); // 依圈數拉高

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
                        '每圈速度時空熱圖',
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '以固定寬度重採樣每圈速度，並標示轉身區段。',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _HeatmapLegend(
                  scale: scale,
                  dataMin: response.dataMin,
                  dataMax: response.dataMax,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryChips(
              width: response.width,
              laps: response.lapCount,
              vmin: colorMin,
              vmax: colorMax,
            ),
            const SizedBox(height: 16),
            _SpeedHeatmapBoard(
              response: response,
              scale: scale,
              height: chartHeight,
            ),
            const SizedBox(height: 8),
            Text(
              '灰線為圈與進度切分，帶有斜線與標籤的區塊代表轉身位置，色階越亮表示速度越高。',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({
    required this.width,
    required this.laps,
    required this.vmin,
    required this.vmax,
  });

  final int width;
  final int laps;
  final double? vmin;
  final double? vmax;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final textStyle =
        textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.72));
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _InfoChip(label: '寬度', value: '$width'),
        _InfoChip(label: '圈數', value: '$laps'),
        _InfoChip(
          label: '色階下限',
          value: vmin?.toStringAsFixed(2) ?? 'auto',
          style: textStyle,
        ),
        _InfoChip(
          label: '色階上限',
          value: vmax?.toStringAsFixed(2) ?? 'auto',
          style: textStyle,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, this.style});

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style:
                style ??
                textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({
    required this.scale,
    required this.dataMin,
    required this.dataMax,
  });

  final _HeatmapColorScale scale;
  final double? dataMin;
  final double? dataMax;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    final minLabel = scale.min ?? dataMin;
    final maxLabel = scale.max ?? dataMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '色階 (m/s)',
          style: textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 200,
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(colors: scale.palette.colors),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minLabel != null ? minLabel.toStringAsFixed(2) : 'auto',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            Text(
              maxLabel != null ? maxLabel.toStringAsFixed(2) : 'auto',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpeedHeatmapBoard extends StatefulWidget {
  const _SpeedHeatmapBoard({
    required this.response,
    required this.scale,
    required this.height,
  });

  final SpeedHeatmapResponse response;
  final _HeatmapColorScale scale;
  final double height;

  @override
  State<_SpeedHeatmapBoard> createState() => _SpeedHeatmapBoardState();
}

class _SpeedHeatmapBoardState extends State<_SpeedHeatmapBoard> {
  Offset? _localPos;
  Size? _boardSize;

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
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final textTheme = context.textTheme;
    const labelWidth = 84.0;
    final accent = DashboardAccentColors.of(context);
    final response = widget.response;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - labelWidth;
        final rowHeight = response.lapCount == 0
            ? widget.height
            : widget.height / response.lapCount;

        // 計算 Hover 資訊
        int? hoverRow;
        int? hoverCol;
        double? hoverSpeed;
        SpeedHeatmapMark? hoverMark;
        String? turnType; // 'Cone' or 'Chair' or null

        if (_localPos != null && _boardSize != null) {
          final dy = _localPos!.dy;
          final dx = _localPos!.dx;

          if (dy >= 0 &&
              dy < _boardSize!.height &&
              dx >= 0 &&
              dx < _boardSize!.width) {
            hoverRow = (dy / rowHeight).floor();
            if (hoverRow >= 0 && hoverRow < response.lapCount) {
              final colWidth = _boardSize!.width / response.width;
              hoverCol = (dx / colWidth).floor();

              if (hoverCol >= 0 && hoverCol < response.width) {
                hoverSpeed = response.heatmap[hoverRow][hoverCol];
              }

              // Check turn regions
              // marks are 1-based lapIndex
              // We find the mark for (hoverRow + 1)
              try {
                hoverMark = response.marks.firstWhere(
                  (m) => m.lapIndex == hoverRow! + 1,
                );
                final frac = dx / _boardSize!.width;

                if (hoverMark.coneStartFrac != null &&
                    hoverMark.coneEndFrac != null) {
                  final start = hoverMark.coneStartFrac!;
                  final end = hoverMark.coneEndFrac!;
                  if (frac >= start && frac <= end) {
                    turnType = 'Cone Turn';
                  }
                }

                if (turnType == null &&
                    hoverMark.chairStartFrac != null &&
                    hoverMark.chairEndFrac != null) {
                  final start = hoverMark.chairStartFrac!;
                  final end = hoverMark.chairEndFrac!;
                  if (frac >= start && frac <= end) {
                    turnType = 'Chair Turn';
                  }
                }
              } catch (_) {
                // No mark for this lap
              }
            }
          }
        }

        return SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Column(
                  children: List.generate(response.lapCount, (index) {
                    final isHoveringRow = hoverRow == index;
                    return Container(
                      height: rowHeight,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      color: isHoveringRow
                          ? colors.onSurface.withValues(alpha: 0.04)
                          : null,
                      child: Text(
                        'Lap ${index + 1}',
                        style: TextStyle(
                          color: isHoveringRow
                              ? colors.onSurface
                              : colors.onSurface.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: isHoveringRow
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: MouseRegion(
                  onHover: _onHover,
                  onExit: _onExit,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            border: Border.all(color: context.dividerColor),
                          ),
                          child: LayoutBuilder(
                            builder: (context, boardConstraints) {
                              // 更新 boardSize 以供計算
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_boardSize != boardConstraints.biggest) {
                                  setState(() {
                                    _boardSize = boardConstraints.biggest;
                                  });
                                }
                              });

                              return CustomPaint(
                                size: Size(availableWidth, widget.height),
                                painter: _SpeedHeatmapPainter(
                                  heatmap: response.heatmap,
                                  marks: {
                                    for (final mark in response.marks)
                                      mark.lapIndex - 1: mark,
                                  },
                                  width: response.width,
                                  scale: widget.scale,
                                  gridColor: context.dividerColor.withValues(
                                    alpha: 0.35,
                                  ),
                                  coneColor: accent.warning.withValues(
                                    alpha: 0.4,
                                  ),
                                  chairColor: accent.success.withValues(
                                    alpha: 0.4,
                                  ),
                                  backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.15),
                                  hoverRow: hoverRow,
                                  hoverCol: hoverCol,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Tooltip Overlay
                      if (_localPos != null &&
                          hoverRow != null &&
                          hoverCol != null)
                        Positioned(
                          left: _localPos!.dx + 16, // Offset tooltip to right
                          top: _localPos!.dy + 16,
                          child: IgnorePointer(
                            child: FractionalTranslation(
                              translation: const Offset(
                                0,
                                0,
                              ), // Adjust if needed to keep on screen
                              child: DashboardGlassTooltip(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lap ${hoverRow + 1}',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colors.onSurfaceVariant
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          hoverSpeed?.toStringAsFixed(2) ?? '-',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: colors.onSurface,
                                                fontWeight: FontWeight.bold,
                                                fontFeatures: [
                                                  const ui.FontFeature.tabularFigures(),
                                                ],
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'm/s',
                                          style: textTheme.bodySmall
                                              ?.copyWith(
                                                color: colors.onSurface
                                                    .withValues(alpha: 0.72),
                                              ),
                                        ),
                                      ],
                                    ),
                                    if (turnType != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: turnType == 'Cone Turn'
                                              ? accent.warning.withValues(
                                                  alpha: 0.2,
                                                )
                                              : accent.success.withValues(
                                                  alpha: 0.2,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: turnType == 'Cone Turn'
                                                ? accent.warning.withValues(
                                                    alpha: 0.5,
                                                  )
                                                : accent.success.withValues(
                                                    alpha: 0.5,
                                                  ),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          turnType,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: turnType == 'Cone Turn'
                                                ? accent.warning
                                                : accent.success,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
        );
      },
    );
  }
}

class _SpeedHeatmapPainter extends CustomPainter {
  _SpeedHeatmapPainter({
    required this.heatmap,
    required this.marks,
    required this.width,
    required this.scale,
    required this.gridColor,
    required this.coneColor,
    required this.chairColor,
    required this.backgroundColor,
    this.hoverRow,
    this.hoverCol,
  });

  final List<List<double?>> heatmap;
  final Map<int, SpeedHeatmapMark> marks;
  final int width;
  final _HeatmapColorScale scale;
  final Color gridColor;
  final Color coneColor;
  final Color chairColor;
  final Color backgroundColor;
  final int? hoverRow;
  final int? hoverCol;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || heatmap.isEmpty || width <= 0) {
      return;
    }

    final rows = heatmap.length;
    final cols = width;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    // 背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    // 熱圖格子
    for (var r = 0; r < rows; r++) {
      final row = heatmap[r];
      final y = r * cellHeight;
      final limit = math.min(cols, row.length);
      for (var c = 0; c < limit; c++) {
        final value = row[c];
        if (value == null || value.isNaN || value.isInfinite) {
          continue;
        }
        final color = scale.colorFor(value);
        if (color == null) {
          continue;
        }
        // 繪製格子時稍微放大一點點以消除縫隙
        final rect = Rect.fromLTWH(
          c * cellWidth,
          y,
          cellWidth + 0.5,
          cellHeight + 0.5,
        );
        canvas.drawRect(rect, Paint()..color = color);
      }
    }

    // 繪製 Hover Highlight (單格)
    if (hoverRow != null && hoverCol != null) {
      if (hoverRow! >= 0 &&
          hoverRow! < rows &&
          hoverCol! >= 0 &&
          hoverCol! < cols) {
        final highlightRect = Rect.fromLTWH(
          hoverCol! * cellWidth,
          hoverRow! * cellHeight,
          cellWidth,
          cellHeight,
        );

        // 畫一個外框或亮色疊加
        canvas.drawRect(
          highlightRect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          highlightRect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // 繪製轉身區段
    marks.forEach((rowIndex, mark) {
      if (rowIndex < 0 || rowIndex >= rows) {
        return;
      }
      final y = rowIndex * cellHeight;

      // 錐桶轉身
      if (mark.coneStartFrac != null && mark.coneEndFrac != null) {
        _drawTurnArea(
          canvas: canvas,
          startFrac: mark.coneStartFrac!,
          endFrac: mark.coneEndFrac!,
          width: size.width,
          y: y,
          h: cellHeight,
          color: coneColor,
          label: 'Cone',
          isHighContrast: true,
        );
      }

      // 椅子轉身 (如果有的話)
      if (mark.chairStartFrac != null && mark.chairEndFrac != null) {
        _drawTurnArea(
          canvas: canvas,
          startFrac: mark.chairStartFrac!,
          endFrac: mark.chairEndFrac!,
          width: size.width,
          y: y,
          h: cellHeight,
          color: chairColor,
          label: 'Chair',
          isHighContrast: true,
        );
      }
    });

    // 水平分隔線
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var r = 1; r < rows; r++) {
      final y = r * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 稀疏的垂直分隔線（6 等分）
    const segments = 6;
    for (var i = 1; i < segments; i++) {
      final x = size.width * (i / segments);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // 繪製外框 (讓整個圖表更完整)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = gridColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawTurnArea({
    required Canvas canvas,
    required double startFrac,
    required double endFrac,
    required double width,
    required double y,
    required double h,
    required Color color,
    required String label,
    bool isHighContrast = false,
  }) {
    final start = (startFrac.clamp(0.0, 1.0)) * width;
    final end = (endFrac.clamp(0.0, 1.0)) * width;
    if (end <= start) return;

    final rect = Rect.fromLTWH(start, y, end - start, h);

    // 1. 背景色 (稍微加強)
    // 若為高對比模式，使用較不飽和的白色/灰色底讓顏色凸顯，或者直接用原色但加深
    final bgColor = isHighContrast
        ? color.withValues(alpha: 0.25)
        : color.withValues(alpha: 0.15);
    canvas.drawRect(rect, Paint()..color = bgColor);

    // 2. 斜線紋理
    canvas.save();
    canvas.clipRect(rect);

    // 高對比模式下使用白色或深色線條，而非半透明色
    final stripeColor = isHighContrast
        ? Colors.white.withValues(alpha: 0.5)
        : color.withValues(alpha: 0.5);

    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = isHighContrast ? 1.5 : 1.0
      ..style = PaintingStyle.stroke;

    // 繪製 45 度斜線 (增加密度)
    final stripeDist = isHighContrast ? 6.0 : 8.0;
    final diagCount = (rect.width + rect.height) / stripeDist;
    for (var i = 0; i < diagCount; i++) {
      final offset = i * stripeDist;
      final p1 = Offset(rect.left + offset, rect.top - 10);
      final p2 = Offset(
        rect.left + offset - rect.height - 20,
        rect.bottom + 10,
      );
      canvas.drawLine(p1, p2, stripePaint);
    }
    canvas.restore();

    // 3. 邊框
    final borderColor = isHighContrast
        ? Colors.white.withValues(alpha: 0.9)
        : color.withValues(alpha: 0.8);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighContrast ? 2.0 : 1.5;
    canvas.drawRect(rect, borderPaint);

    // 4. 文字標籤 (只在寬度足夠時顯示)
    if (rect.width > 24) {
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 3, color: Colors.black, offset: Offset(0, 1)),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: rect.width);

      // 置中
      final textX = rect.left + (rect.width - textPainter.width) / 2;
      final textY = rect.top + (rect.height - textPainter.height) / 2;

      // 增加文字背景膠囊以提高可讀性
      final bgRect = Rect.fromLTWH(
        textX - 4,
        textY - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      final bgPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      final bgRRect = RRect.fromRectAndRadius(bgRect, const Radius.circular(4));
      canvas.drawRRect(bgRRect, bgPaint);

      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedHeatmapPainter oldDelegate) {
    return oldDelegate.heatmap != heatmap ||
        oldDelegate.width != width ||
        oldDelegate.scale != scale ||
        oldDelegate.marks != marks ||
        oldDelegate.chairColor != chairColor ||
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
    if (min == null || max == null) {
      return null;
    }
    final domain = max! - min!;
    if (domain.abs() < 1e-6) {
      return palette.colorAt(0.5);
    }
    final t = ((value - min!) / domain).clamp(0.0, 1.0);
    return palette.colorAt(t);
  }
}
