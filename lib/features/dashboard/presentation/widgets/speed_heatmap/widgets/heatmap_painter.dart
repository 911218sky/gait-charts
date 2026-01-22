import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import 'heatmap_color_scale.dart';

/// 熱圖繪製器，負責繪製熱圖格子、轉身區段、hover 效果。
class SpeedHeatmapPainter extends CustomPainter {
  SpeedHeatmapPainter({
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
  final HeatmapColorScale scale;
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

      // 椅子轉身
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

    // 繪製外框
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

    // 背景色
    final bgColor = isHighContrast
        ? color.withValues(alpha: 0.25)
        : color.withValues(alpha: 0.15);
    canvas.drawRect(rect, Paint()..color = bgColor);

    // 斜線紋理
    canvas.save();
    canvas.clipRect(rect);

    final stripeColor = isHighContrast
        ? Colors.white.withValues(alpha: 0.5)
        : color.withValues(alpha: 0.5);

    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = isHighContrast ? 1.5 : 1.0
      ..style = PaintingStyle.stroke;

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

    // 邊框
    final borderColor = isHighContrast
        ? Colors.white.withValues(alpha: 0.9)
        : color.withValues(alpha: 0.8);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighContrast ? 2.0 : 1.5;
    canvas.drawRect(rect, borderPaint);

    // 文字標籤（只在寬度足夠時顯示）
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

      final textX = rect.left + (rect.width - textPainter.width) / 2;
      final textY = rect.top + (rect.height - textPainter.height) / 2;

      // 文字背景膠囊
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
  bool shouldRepaint(covariant SpeedHeatmapPainter oldDelegate) {
    return oldDelegate.heatmap != heatmap ||
        oldDelegate.width != width ||
        oldDelegate.scale != scale ||
        oldDelegate.marks != marks ||
        oldDelegate.chairColor != chairColor ||
        oldDelegate.hoverRow != hoverRow ||
        oldDelegate.hoverCol != hoverCol;
  }
}
