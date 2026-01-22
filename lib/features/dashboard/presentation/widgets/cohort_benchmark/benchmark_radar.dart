import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';

@immutable
class BenchmarkRadarEntry {
  const BenchmarkRadarEntry({
    required this.key,
    required this.label,
    required this.percentile01,
    required this.valueText,
    required this.status,
    required this.color,
  });

  final String key;
  final String label;
  final double percentile01; // 0..1
  final String valueText;
  final MetricComparisonStatus status;
  final Color color;
}

/// 以 percentile_position (0..100) 畫雷達圖：
/// - 使用者 polygon：各指標 percentile
/// - 族群參考：P25..P75 band + P50 ring
class BenchmarkRadar extends StatefulWidget {
  const BenchmarkRadar({
    required this.title,
    required this.subtitle,
    required this.entries,
    super.key,
    this.height = 280,
    this.showLegend = true,
    this.showAxisLabels = true,
  });

  final String title;
  final String subtitle;
  final List<BenchmarkRadarEntry> entries;
  final double height;
  final bool showLegend;
  final bool showAxisLabels;

  @override
  State<BenchmarkRadar> createState() => _BenchmarkRadarState();
}

class _BenchmarkRadarState extends State<BenchmarkRadar> {
  int? _hoveredIndex;

  bool get _hasData =>
      widget.entries.isNotEmpty &&
      widget.entries.any((e) => e.percentile01.isFinite && e.percentile01 > 0);

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
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        const _RadarLegendHint(),
        const SizedBox(height: 16),
        if (!_hasData)
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Center(
              child: Text(
                '沒有可視化的比對資料',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
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
                final hoveredPoint = _hoveredIndex != null &&
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
                            painter: _BenchmarkRadarPainter(
                              entries: widget.entries,
                              layout: layout,
                              hoveredIndex: _hoveredIndex,
                              colors: colors,
                              isDark: isDark,
                              showAxisLabels: widget.showAxisLabels,
                            ),
                          ),
                        ),
                        if (hoveredPoint != null)
                          Positioned(
                            left: hoveredPoint.dx,
                            top: hoveredPoint.dy,
                            child: FractionalTranslation(
                              translation: const Offset(-0.5, -1.2),
                              child: _BenchmarkRadarTooltip(
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
        if (_hasData && widget.showLegend) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final entry in widget.entries) _BenchmarkLegendChip(entry: entry),
            ],
          ),
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
      final ratio = widget.entries[i].percentile01.clamp(0.0, 1.0);
      // 線性映射（避免把小差異視覺放大）
      final eased = ratio;
      final angle = -math.pi / 2 + angleStep * i;
      pointOffsets.add(
        Offset(
          center.dx + radius * eased * math.cos(angle),
          center.dy + radius * eased * math.sin(angle),
        ),
      );
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

class _BenchmarkRadarPainter extends CustomPainter {
  const _BenchmarkRadarPainter({
    required this.entries,
    required this.layout,
    required this.hoveredIndex,
    required this.colors,
    required this.isDark,
    required this.showAxisLabels,
  });

  final List<BenchmarkRadarEntry> entries;
  final _RadarLayout layout;
  final int? hoveredIndex;
  final ColorScheme colors;
  final bool isDark;
  final bool showAxisLabels;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty || layout.radius <= 0) return;

    final center = layout.center;
    final radius = layout.radius;
    final pointOffsets = layout.pointOffsets;

    // Grid (25/50/75/100) + normal band (25~75) + median ring (50)
    const steps = <double>[0.25, 0.5, 0.75, 1.0];
    final gridPaint = Paint()
      ..color = colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.05)
      ..style = PaintingStyle.stroke;

    // Normal band fill (between 0.25 and 0.75)
    final bandPaint = Paint()
      ..color = colors.primary.withValues(alpha: isDark ? 0.06 : 0.04)
      ..style = PaintingStyle.fill;
    final bandPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: radius * 0.75))
      ..addOval(Rect.fromCircle(center: center, radius: radius * 0.25));
    canvas.drawPath(bandPath, bandPaint);

    for (final s in steps) {
      canvas.drawCircle(center, radius * s, gridPaint);
    }

    final medianPaint = Paint()
      ..color = colors.primary.withValues(alpha: isDark ? 0.35 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius * 0.5, medianPaint);

    final axisPaint = Paint()
      ..color = colors.onSurface.withValues(alpha: isDark ? 0.12 : 0.08)
      ..strokeWidth = 1.2;

    final angleStep = (2 * math.pi) / entries.length;
    for (var i = 0; i < entries.length; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final axisEnd = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, axisEnd, axisPaint);
    }

    if (showAxisLabels) {
      for (var i = 0; i < entries.length; i++) {
        final angle = -math.pi / 2 + angleStep * i;
        final labelRadius = radius * 1.06;
        final labelPos = Offset(
          center.dx + labelRadius * math.cos(angle),
          center.dy + labelRadius * math.sin(angle),
        );

        final text = _compactLabel(entries[i].label, maxChars: 10);
        final painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: colors.onSurfaceVariant.withValues(alpha: 0.92),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: 110);

        // 根據象限微調對齊，避免文字蓋到圖形中心
        final dx = labelPos.dx -
            (math.cos(angle) >= 0 ? 0 : painter.width) -
            (math.cos(angle).abs() < 0.2 ? painter.width / 2 : 0);
        final dy = labelPos.dy -
            (math.sin(angle) >= 0 ? 0 : painter.height) -
            (math.sin(angle).abs() < 0.2 ? painter.height / 2 : 0);

        painter.paint(canvas, Offset(dx, dy));
      }
    }

    // User polygon
    if (pointOffsets.length >= 3) {
      final polygon = Path()..addPolygon(pointOffsets, true);
      final fillPaint = Paint()
        ..color = colors.secondary.withValues(alpha: isDark ? 0.10 : 0.06)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = colors.secondary.withValues(alpha: isDark ? 0.55 : 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawPath(polygon, fillPaint);
      canvas.drawPath(polygon, borderPaint);
    } else if (pointOffsets.length == 2) {
      final borderPaint = Paint()
        ..color = colors.secondary.withValues(alpha: isDark ? 0.55 : 0.35)
        ..strokeWidth = 1.8;
      canvas.drawLine(pointOffsets[0], pointOffsets[1], borderPaint);
    } else if (pointOffsets.length == 1) {
      final markerPaint = Paint()
        ..color = colors.secondary.withValues(alpha: isDark ? 0.55 : 0.35)
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
        ..color = (isDark ? Colors.black : Colors.white)
            .withValues(alpha: isHovered ? 0.5 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 1.4 : 1;
      canvas.drawCircle(pointOffsets[i], markerRadius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BenchmarkRadarPainter oldDelegate) {
    return !listEquals(entries, oldDelegate.entries) ||
        hoveredIndex != oldDelegate.hoveredIndex ||
        layout.center != oldDelegate.layout.center ||
        layout.radius != oldDelegate.layout.radius ||
        !listEquals(layout.pointOffsets, oldDelegate.layout.pointOffsets) ||
        showAxisLabels != oldDelegate.showAxisLabels;
  }
}

String _compactLabel(String input, {required int maxChars}) {
  final trimmed = input.trim();
  if (trimmed.length <= maxChars) return trimmed;
  return '${trimmed.substring(0, maxChars)}…';
}

class _BenchmarkRadarTooltip extends StatelessWidget {
  const _BenchmarkRadarTooltip({required this.entry});

  final BenchmarkRadarEntry entry;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final colors = context.colorScheme;
    final palette = DashboardBenchmarkCompareColors.of(context);
    final statusColor = switch (entry.status) {
      MetricComparisonStatus.worse => palette.lower,
      MetricComparisonStatus.better => palette.inRange,
      MetricComparisonStatus.similar => palette.higher,
    };

    final pct = (entry.percentile01 * 200).clamp(0.0, 200.0).toStringAsFixed(1);
    final background =
        isDark ? const Color(0xFF111111) : Colors.black.withValues(alpha: 0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: context.textTheme.bodySmall!.copyWith(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '相對族群：$pct%',
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.valueText,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
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

class _RadarLegendHint extends StatelessWidget {
  const _RadarLegendHint();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final palette = DashboardBenchmarkCompareColors.of(context);

    Widget dot(Color c) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '帶狀：P25-P75（參考區間）',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        Text(
          '環線：P50（中位數）',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(palette.inRange),
            const SizedBox(width: 6),
            Text(
              '區間內',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(palette.lower),
            const SizedBox(width: 6),
            Text(
              '較低（<P25）',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(palette.higher),
            const SizedBox(width: 6),
            Text(
              '較高（>P75）',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BenchmarkLegendChip extends StatelessWidget {
  const _BenchmarkLegendChip({required this.entry});

  final BenchmarkRadarEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final pct =
        (entry.percentile01 * 100).clamp(0.0, 100.0).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
        color: colors.surfaceContainerLow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: entry.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            entry.label,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$pct%',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

