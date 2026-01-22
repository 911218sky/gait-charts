import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';

/// 雷達圖所需的資料，預先計算好比例。
class StageRadarEntry {
  const StageRadarEntry({
    required this.label,
    required this.seconds,
    required this.ratio,
    required this.color,
  });

  final String label;
  final double seconds;
  final double ratio;
  final Color color;

  StageRadarEntry copyWith({
    String? label,
    double? seconds,
    double? ratio,
    Color? color,
  }) {
    return StageRadarEntry(
      label: label ?? this.label,
      seconds: seconds ?? this.seconds,
      ratio: ratio ?? this.ratio,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is StageRadarEntry &&
        other.label == label &&
        other.seconds == seconds &&
        other.ratio == ratio &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(label, seconds, ratio, color);
}

/// 通用的階段占比雷達圖組件，可被單圈與統計共用。
class StageDurationRadar extends StatefulWidget {
  const StageDurationRadar({
    required this.entries,
    required this.centerLabel,
    required this.centerValue,
    super.key,
    this.title = '階段占比雷達圖',
    this.subtitle = '觀察每個階段耗時佔整體的比例',
    this.height = 260,
    this.showLegend = true,
    this.pointPadding = 0.3,
  });

  final List<StageRadarEntry> entries;
  final String centerLabel;
  final String centerValue;
  final String title;
  final String subtitle;
  final double height;
  final bool showLegend;
  final double pointPadding;

  @override
  State<StageDurationRadar> createState() => _StageDurationRadarState();
}

class _StageDurationRadarState extends State<StageDurationRadar> {
  int? _hoveredIndex;

  // 只要其中一個節點有佔比即可繪製雷達圖，否則顯示空狀態。
  bool get _hasData =>
      widget.entries.isNotEmpty &&
      widget.entries.any((entry) => entry.ratio > 0);

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          style: context.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        if (!_hasData)
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.onSurface.withValues(alpha: 0.08)),
            ),
            child: Center(
              child: Text(
                '沒有可視化的階段資料',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else ...[
          SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final resolvedWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : widget.height;
                final resolvedHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : widget.height;
                final chartSize = Size(resolvedWidth, resolvedHeight);
                final layout = _computeLayout(chartSize);
                final hoveredPoint =
                    _hoveredIndex != null &&
                        _hoveredIndex! < layout.pointOffsets.length
                    ? layout.pointOffsets[_hoveredIndex!]
                    : null;

                return SizedBox.expand(
                  child: MouseRegion(
                    onHover: (event) =>
                        _handleHover(event.localPosition, layout),
                    onExit: (_) => _clearHover(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _StageRadarPainter(
                              entries: widget.entries,
                              layout: layout,
                              hoveredIndex: _hoveredIndex,
                              colors: colors,
                              isDark: isDark,
                            ),
                            // 中心文字顯示目前情境的摘要資訊。
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.centerLabel,
                                    style: context.textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    widget.centerValue,
                                    style: context.textTheme.titleMedium
                                        ?.copyWith(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (hoveredPoint != null)
                          Positioned(
                            left: hoveredPoint.dx,
                            top: hoveredPoint.dy,
                            child: FractionalTranslation(
                              translation: const Offset(-0.5, -1.2),
                              child: _RadarTooltip(
                                entry: widget.entries[_hoveredIndex!],
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
          if (widget.showLegend) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final entry in widget.entries)
                  _StageRadarLegendChip(entry: entry),
              ],
            ),
          ],
        ],
      ],
    );
  }

  _RadarLayout _computeLayout(Size size) {
    final radius = math.min(size.width, size.height) / 2 - 12;
    final center = size.center(Offset.zero);
    if (radius <= 0 || widget.entries.isEmpty) {
      return _RadarLayout(
        center: center,
        radius: radius,
        pointOffsets: const <Offset>[],
      );
    }
    final pointOffsets = <Offset>[];
    final angleStep = (2 * math.pi) / widget.entries.length;
    for (var i = 0; i < widget.entries.length; i++) {
      final ratio = widget.entries[i].ratio.clamp(0.0, 1.0);
      // 使用平方根縮放，減少小比例時節點擠在中心的情況。
      final easedRatio = ratio <= 0
          ? 0.0
          : math.pow(ratio, 0.65).toDouble().clamp(0.0, 1.0);
      // 額外加入 padding 讓節點視覺上離中心更遠，可被外部參數調整。
      final paddedRatio = (easedRatio + widget.pointPadding).clamp(0.0, 1.0);
      final angle = -math.pi / 2 + angleStep * i;
      final point = Offset(
        center.dx + radius * paddedRatio * math.cos(angle),
        center.dy + radius * paddedRatio * math.sin(angle),
      );
      pointOffsets.add(point);
    }
    return _RadarLayout(
      center: center,
      radius: radius,
      pointOffsets: List.unmodifiable(pointOffsets),
    );
  }

  void _handleHover(Offset position, _RadarLayout layout) {
    final hovered = _hitTestPoint(position, layout);
    if (hovered != _hoveredIndex) {
      setState(() => _hoveredIndex = hovered);
    }
  }

  int? _hitTestPoint(Offset position, _RadarLayout layout) {
    const hitRadius = 16.0;
    for (var i = 0; i < layout.pointOffsets.length; i++) {
      if ((layout.pointOffsets[i] - position).distance <= hitRadius) {
        return i;
      }
    }
    return null;
  }

  void _clearHover() {
    if (_hoveredIndex != null) {
      setState(() => _hoveredIndex = null);
    }
  }
}

/// 呈現單一雷達節點的 legend。
class _StageRadarLegendChip extends StatelessWidget {
  const _StageRadarLegendChip({required this.entry});

  final StageRadarEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: isDark ? 0.03 : 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.05)),
      ),
      // 以圓點 + 文字 + 時間/比例並列成一顆 legend。
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: entry.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.label,
            style: TextStyle(color: colors.onSurface, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.seconds.toStringAsFixed(1)} s · ${(entry.ratio * 100).clamp(0.0, 100.0).toStringAsFixed(0)}%',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 自訂雷達圖 painter，使用平方根縮放避免節點擠在中心。
class _StageRadarPainter extends CustomPainter {
  const _StageRadarPainter({
    required this.entries,
    required this.layout,
    required this.hoveredIndex,
    required this.colors,
    required this.isDark,
  });

  final List<StageRadarEntry> entries;
  final _RadarLayout layout;
  final int? hoveredIndex;
  final ColorScheme colors;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty || layout.radius <= 0) {
      return;
    }
    final center = layout.center;
    final radius = layout.radius;
    final pointOffsets = layout.pointOffsets;

    const gridSteps = 4;
    final gridPaint = Paint()
      ..color = colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.05)
      ..style = PaintingStyle.stroke;
    // 先畫出等距同心圓作為比例輔助格線。
    for (var i = 1; i <= gridSteps; i++) {
      final levelRadius = radius * (i / gridSteps);
      canvas.drawCircle(center, levelRadius, gridPaint);
    }

    final axisPaint = Paint()
      ..color = colors.onSurface.withValues(alpha: isDark ? 0.12 : 0.08)
      ..strokeWidth = 1.2;

    final angleStep = (2 * math.pi) / entries.length;
    for (var i = 0; i < entries.length; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      // 每個節點都從中心向外畫出一條軸線。
      final axisEnd = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, axisEnd, axisPaint);
    }

    if (pointOffsets.length >= 3) {
      final polygon = Path()..addPolygon(pointOffsets, true);
      final fillPaint = Paint()
        ..color = colors.primary.withValues(alpha: isDark ? 0.07 : 0.04)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = colors.primary.withValues(alpha: isDark ? 0.45 : 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      // 有三個以上節點時填滿多邊形，模擬雷達圖。
      canvas.drawPath(polygon, fillPaint);
      canvas.drawPath(polygon, borderPaint);
    } else if (pointOffsets.length == 2) {
      final borderPaint = Paint()
        ..color = colors.primary.withValues(alpha: isDark ? 0.45 : 0.35)
        ..strokeWidth = 1.6;
      canvas.drawLine(pointOffsets[0], pointOffsets[1], borderPaint);
    } else if (pointOffsets.length == 1) {
      final markerPaint = Paint()
        ..color = colors.primary.withValues(alpha: isDark ? 0.45 : 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pointOffsets[0], 4, markerPaint);
    }

    for (var i = 0; i < pointOffsets.length; i++) {
      final isHovered = hoveredIndex == i;
      final markerRadius = isHovered ? 6.5 : 4.5;
      final markerPaint = Paint()
        ..color = entries[i].color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pointOffsets[i], markerRadius, markerPaint);
      final borderPaint = Paint()
        ..color = (isDark ? Colors.black : Colors.white).withValues(alpha: isHovered ? 0.5 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 1.4 : 1;
      canvas.drawCircle(pointOffsets[i], markerRadius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StageRadarPainter oldDelegate) {
    return !listEquals(entries, oldDelegate.entries) ||
        hoveredIndex != oldDelegate.hoveredIndex ||
        layout.center != oldDelegate.layout.center ||
        layout.radius != oldDelegate.layout.radius ||
        !listEquals(layout.pointOffsets, oldDelegate.layout.pointOffsets);
  }
}

class _RadarTooltip extends StatelessWidget {
  const _RadarTooltip({required this.entry});

  final StageRadarEntry entry;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final ratioText = (entry.ratio * 100).clamp(0.0, 100.0).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.label,
            style: context.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.seconds.toStringAsFixed(1)} s · $ratioText%',
            style: context.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _RadarLayout {
  const _RadarLayout({
    required this.center,
    required this.radius,
    required this.pointOffsets,
  });

  final Offset center;
  final double radius;
  final List<Offset> pointOffsets;
}
