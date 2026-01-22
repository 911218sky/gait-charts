import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// 軌跡播放器的圖例覆蓋層。
class LegendOverlay extends StatelessWidget {
  const LegendOverlay({
    required this.chairColor,
    required this.coneColor,
    required this.markerColor,
    required this.heatmapColors,
    super.key,
  });

  final Color chairColor;
  final Color coneColor;
  final Color markerColor;
  final List<Color> heatmapColors;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : colors.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.onSurface.withValues(alpha: isDark ? 0.1 : 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(
            icon: Icon(Icons.crop_square_rounded, size: 14, color: chairColor),
            label: 'Chair',
          ),
          const SizedBox(height: 6),
          _LegendItem(
            icon: Icon(Icons.change_history, size: 14, color: coneColor),
            label: 'Cone',
          ),
          const SizedBox(height: 6),
          _LegendItem(
            icon: _HeatmapLegendSwatch(colors: heatmapColors),
            label: 'Trajectory',
          ),
          const SizedBox(height: 12),
          Text(
            'Turn Markers',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          _LegendItem(
            icon: Icon(Icons.circle_outlined, size: 14, color: coneColor),
            label: 'Start (Cone)',
          ),
          const SizedBox(height: 6),
          _LegendItem(
            icon: Icon(Icons.close, size: 14, color: coneColor),
            label: 'End (Cone)',
          ),
          const SizedBox(height: 6),
          _LegendItem(
            icon: _DiamondIcon(color: chairColor, size: 10),
            label: 'Start (Chair)',
          ),
          const SizedBox(height: 6),
          _LegendItem(
            icon: Icon(Icons.add, size: 14, color: chairColor),
            label: 'End (Chair)',
          ),
        ],
      ),
    );
  }
}

class _HeatmapLegendSwatch extends StatelessWidget {
  const _HeatmapLegendSwatch({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final effective = colors.isEmpty ? [context.colorScheme.primary] : colors;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: effective,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 16, height: 16, child: Center(child: icon)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DiamondIcon extends StatelessWidget {
  const _DiamondIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(border: Border.all(color: color, width: 1.5)),
      ),
    );
  }
}
