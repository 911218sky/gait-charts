import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// 軌跡繪製器：負責在 Canvas 上繪製軌跡、場景物件和標記。
class TrajectoryPainter extends CustomPainter {
  TrajectoryPainter({
    required this.payload,
    required this.playheadListenable,
    required this.trailColor,
    required this.markerColor,
    required this.chairColor,
    required this.coneColor,
    required this.gridColor,
    required this.axisColor,
    required this.heatmapColors,
    required this.showFullTrail,
    required this.showChairArea,
    required this.showConeArea,
  }) : _trailPaint = Paint()
         ..style = PaintingStyle.stroke
         ..strokeWidth = 3.0
         ..strokeCap = StrokeCap.round
         ..strokeJoin = StrokeJoin.round
         ..color = trailColor,
       _markerPaint = Paint()..color = markerColor,
       _axisPaint = Paint()
         ..color = axisColor
         ..strokeWidth = 1.5,
       _gridPaint = Paint()
         ..color = gridColor
         ..strokeWidth = 1.0,
       _borderPaint = Paint()
         ..style = PaintingStyle.stroke
         ..color = gridColor
         ..strokeWidth = 2,
       _textPainter = TextPainter(
         textDirection: TextDirection.ltr,
         textAlign: TextAlign.right,
       ),
       super(repaint: playheadListenable);

  final TrajectoryDecodedPayload payload;
  final ValueListenable<double> playheadListenable;
  final Color trailColor;
  final Color markerColor;
  final Color chairColor;
  final Color coneColor;
  final Color gridColor;
  final Color axisColor;
  final List<Color> heatmapColors;
  final bool showFullTrail;
  final bool showChairArea;
  final bool showConeArea;

  final Paint _trailPaint;
  final Paint _markerPaint;
  final Paint _axisPaint;
  final Paint _gridPaint;
  final Paint _borderPaint;
  final TextPainter _textPainter;

  static const double _padTop = 32.0;
  static const double _padBottom = 100.0;
  static const double _padH = 48.0;

  Size? _lastSize;
  TrajectoryDecodedPayload? _lastPayload;
  TrajectoryBounds? _bounds;
  double? _scale;
  double? _offsetX;
  double? _offsetY;
  Rect? _contentRect;
  List<Offset>? _centerCanvasPoints;

  @override
  void paint(Canvas canvas, Size size) {
    if (payload.nFrames <= 0 || size.isEmpty) return;

    _ensureLayout(size);
    final currentK = playheadListenable.value.round().clamp(0, payload.nFrames - 1);
    final center = payload.centerXy;

    var currentLapIndex = -1;
    var lapStartK = 0;

    for (final lap in payload.laps) {
      if (lap.payloadStartK != null &&
          lap.payloadEndK != null &&
          currentK >= lap.payloadStartK! &&
          currentK <= lap.payloadEndK!) {
        currentLapIndex = lap.lapIndex;
        lapStartK = lap.payloadStartK!;
        break;
      }
    }

    _drawGridAndAxis(canvas);

    if (currentLapIndex != -1) {
      final startK = showFullTrail ? 0 : lapStartK;
      _drawHeatTrail(canvas: canvas, startInclusive: startK, endInclusive: currentK);
    }

    _drawSceneObject(
      canvas: canvas,
      center: payload.sceneWorld.chair,
      radius: payload.sceneWorld.rChair,
      color: chairColor,
      isSquare: true,
      showArea: showChairArea,
    );
    _drawSceneObject(
      canvas: canvas,
      center: payload.sceneWorld.cone,
      radius: payload.sceneWorld.rCone,
      color: coneColor,
      isSquare: false,
      showArea: showConeArea,
    );

    final i = currentK * 2;
    final pL = _toCanvas(payload.leftXy[i], payload.leftXy[i + 1]);
    final pR = _toCanvas(payload.rightXy[i], payload.rightXy[i + 1]);
    final pC = _toCanvas(center[i], center[i + 1]);

    canvas.drawLine(pL, pR, Paint()..color = markerColor..strokeWidth = 2.0);
    canvas.drawCircle(pL, 4.0, _markerPaint);
    canvas.drawCircle(pR, 4.0, _markerPaint);
    canvas.drawCircle(pC, 5.0, _markerPaint);

    if (currentLapIndex != -1) {
      final lap = payload.laps.firstWhere((l) => l.lapIndex == currentLapIndex);
      final m = lap.markers;

      void drawMark(int k, Color c, String type) {
        if (k < 0 || k >= payload.nFrames) return;
        final idx = k * 2;
        final p = _toCanvas(center[idx], center[idx + 1]);
        _drawMarkerShape(canvas, p, c, type);
      }

      if (m.coneStartK != null) drawMark(m.coneStartK!, coneColor, 'cone_start');
      if (m.coneEndK != null) drawMark(m.coneEndK!, coneColor, 'cone_end');
      if (m.chairStartK != null) drawMark(m.chairStartK!, chairColor, 'chair_start');
      if (m.chairEndK != null) drawMark(m.chairEndK!, chairColor, 'chair_end');
    }
  }

  void _ensureLayout(Size size) {
    if (_lastSize == size && identical(_lastPayload, payload)) return;

    _lastSize = size;
    _lastPayload = payload;
    _bounds = payload.meta.bounds;

    final bounds = _bounds!;
    final dx = bounds.dx;
    final dy = bounds.dy;

    final w = (size.width - _padH * 2).clamp(1.0, 1e12);
    final h = (size.height - _padTop - _padBottom).clamp(1.0, 1e12);

    final scale = (w / dx) < (h / dy) ? (w / dx) : (h / dy);
    _scale = scale;

    final contentW = dx * scale;
    final contentH = dy * scale;
    _offsetX = _padH + (w - contentW) * 0.5;
    _offsetY = _padTop + (h - contentH) * 0.5;
    _contentRect = Rect.fromLTWH(_padH, _padTop, size.width - _padH * 2, size.height - _padTop - _padBottom);

    _centerCanvasPoints = List.generate(
      payload.nFrames,
      (k) {
        final i = k * 2;
        return _toCanvas(payload.centerXy[i], payload.centerXy[i + 1]);
      },
      growable: false,
    );
  }

  Offset _toCanvas(double x, double y) {
    final scale = _scale!;
    final bounds = _bounds!;
    final cx = _offsetX! + (x - bounds.xmin) * scale;
    final cy = _offsetY! + (bounds.ymax - y) * scale;
    return Offset(cx, cy);
  }

  void _drawHeatTrail({required Canvas canvas, required int startInclusive, required int endInclusive}) {
    final points = _centerCanvasPoints;
    if (points == null || points.isEmpty) return;

    final start = startInclusive.clamp(0, points.length - 1);
    final end = endInclusive.clamp(0, points.length - 1);
    if (end <= start) return;

    final segCount = (end - start).clamp(1, 1 << 30);
    final denom = ((segCount as num) - 1).abs() < 1e-9 ? 1.0 : (segCount - 1).toDouble();
    final colors = heatmapColors;
    final paletteCount = colors.length;

    Color colorAt(double t) {
      if (paletteCount <= 0) return trailColor;
      if (paletteCount == 1) return colors.first;
      final clamped = t.clamp(0.0, 1.0);
      final scaled = clamped * (paletteCount - 1);
      final i = scaled.floor();
      final frac = scaled - i;
      if (i >= paletteCount - 1) return colors.last;
      return Color.lerp(colors[i], colors[i + 1], frac) ?? colors[i];
    }

    const alphaOld = 0.18;
    const alphaNew = 0.95;

    for (var k = start; k < end; k++) {
      final t = segCount <= 1 ? 1.0 : (k - start) / denom;
      final a = lerpDouble(alphaOld, alphaNew, t) ?? alphaNew;
      _trailPaint.color = colorAt(t).withValues(alpha: a);
      canvas.drawLine(points[k], points[k + 1], _trailPaint);
    }
  }

  void _drawGridAndAxis(Canvas canvas) {
    final rect = _contentRect!;
    final bounds = _bounds!;
    final scale = _scale!;

    const stepPx = 50.0;
    for (var x = _padH; x < rect.right; x += stepPx) {
      canvas.drawLine(Offset(x, _padTop), Offset(x, rect.bottom), _gridPaint);
    }
    for (var y = _padTop; y < rect.bottom; y += stepPx) {
      canvas.drawLine(Offset(_padH, y), Offset(rect.right, y), _gridPaint);
    }

    canvas.drawRect(rect, _borderPaint);

    // Y Axis
    final worldHeight = rect.height / scale;
    final stepWorldY = _niceStep(worldHeight / 6);
    final startY = (bounds.ymin / stepWorldY).ceil() * stepWorldY;

    for (var y = startY; y <= bounds.ymax; y += stepWorldY) {
      final cy = _offsetY! + (bounds.ymax - y) * scale;
      if (cy < rect.top || cy > rect.bottom) continue;

      canvas.drawLine(Offset(rect.left, cy), Offset(rect.left - 6, cy), _axisPaint);
      _textPainter.text = TextSpan(
        text: '${y.toStringAsFixed(1)}m',
        style: TextStyle(color: axisColor.withValues(alpha: 0.8), fontSize: 10),
      );
      _textPainter.layout();
      _textPainter.paint(canvas, Offset(rect.left - 8 - _textPainter.width, cy - _textPainter.height / 2));
    }

    // X Axis
    final worldWidth = rect.width / scale;
    final stepWorldX = _niceStep(worldWidth / 8);
    final startX = (bounds.xmin / stepWorldX).ceil() * stepWorldX;

    for (var x = startX; x <= bounds.xmax; x += stepWorldX) {
      final cx = _offsetX! + (x - bounds.xmin) * scale;
      if (cx < rect.left || cx > rect.right) continue;

      canvas.drawLine(Offset(cx, rect.bottom), Offset(cx, rect.bottom + 6), _axisPaint);
      _textPainter.text = TextSpan(
        text: '${x.toStringAsFixed(1)}m',
        style: TextStyle(color: axisColor.withValues(alpha: 0.8), fontSize: 10),
      );
      _textPainter.layout();
      _textPainter.paint(canvas, Offset(cx - _textPainter.width / 2, rect.bottom + 8));
    }
  }

  double _niceStep(double range) {
    final exponent = (log(range) / ln10).floor();
    final fraction = range / pow(10, exponent);
    double niceFraction;
    if (fraction < 1.5) {
      niceFraction = 1;
    } else if (fraction < 3) {
      niceFraction = 2;
    } else if (fraction < 7) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
    return niceFraction * pow(10, exponent);
  }

  void _drawSceneObject({
    required Canvas canvas,
    required Point<double> center,
    required double radius,
    required Color color,
    required bool showArea,
    bool isSquare = false,
  }) {
    final c = _toCanvas(center.x, center.y);
    final r = (radius * (_scale ?? 1)).abs();

    if (showArea) {
      final fill = Paint()..style = PaintingStyle.fill..color = color.withValues(alpha: 0.15);
      final stroke = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = color.withValues(alpha: 0.5);
      canvas.drawCircle(c, r, fill);
      canvas.drawCircle(c, r, stroke);
    }

    final shapePaint = Paint()..color = color;
    if (isSquare) {
      canvas.drawRect(Rect.fromCenter(center: c, width: 14, height: 14), shapePaint);
    } else {
      final path = Path();
      path.moveTo(c.dx, c.dy - 8);
      path.lineTo(c.dx + 7, c.dy + 6);
      path.lineTo(c.dx - 7, c.dy + 6);
      path.close();
      canvas.drawPath(path, shapePaint);
    }
  }

  void _drawMarkerShape(Canvas canvas, Offset p, Color color, String type) {
    final paint = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke;

    canvas.drawCircle(p, 10, Paint()..color = color.withValues(alpha: 0.3)..style = PaintingStyle.fill);

    if (type.contains('cone')) {
      if (type.contains('start')) {
        canvas.drawCircle(p, 6, paint);
      } else {
        const d = 5.0;
        canvas.drawLine(p + const Offset(-d, -d), p + const Offset(d, d), paint);
        canvas.drawLine(p + const Offset(-d, d), p + const Offset(d, -d), paint);
      }
    } else {
      if (type.contains('start')) {
        final path = Path();
        const d = 7.0;
        path.moveTo(p.dx, p.dy - d);
        path.lineTo(p.dx + d, p.dy);
        path.lineTo(p.dx, p.dy + d);
        path.lineTo(p.dx - d, p.dy);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        const d = 6.0;
        canvas.drawLine(p + const Offset(0, -d), p + const Offset(0, d), paint);
        canvas.drawLine(p + const Offset(-d, 0), p + const Offset(d, 0), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TrajectoryPainter oldDelegate) {
    return oldDelegate.payload != payload ||
        oldDelegate.trailColor != trailColor ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.chairColor != chairColor ||
        oldDelegate.coneColor != coneColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.heatmapColors != heatmapColors ||
        oldDelegate.showFullTrail != showFullTrail ||
        oldDelegate.playheadListenable != playheadListenable;
  }
}
