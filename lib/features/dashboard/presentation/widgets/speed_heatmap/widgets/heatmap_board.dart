import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

import 'heatmap_color_scale.dart';
import 'heatmap_painter.dart';

/// 熱圖主體，包含 hover 互動與 tooltip。
class SpeedHeatmapBoard extends StatefulWidget {
  const SpeedHeatmapBoard({
    required this.response,
    required this.scale,
    required this.height,
    super.key,
  });

  final SpeedHeatmapResponse response;
  final HeatmapColorScale scale;
  final double height;

  @override
  State<SpeedHeatmapBoard> createState() => _SpeedHeatmapBoardState();
}

class _SpeedHeatmapBoardState extends State<SpeedHeatmapBoard> {
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
        final hoverInfo = _calculateHoverInfo(rowHeight);

        return SizedBox(
          height: widget.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左側 Lap 標籤
              _buildLapLabels(
                colors: colors,
                rowHeight: rowHeight,
                hoverRow: hoverInfo.row,
              ),
              // 右側熱圖
              Expanded(
                child: MouseRegion(
                  onHover: _onHover,
                  onExit: _onExit,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildHeatmapCanvas(
                        availableWidth: availableWidth,
                        accent: accent,
                        colors: colors,
                        hoverRow: hoverInfo.row,
                        hoverCol: hoverInfo.col,
                      ),
                      // Tooltip
                      if (_localPos != null &&
                          hoverInfo.row != null &&
                          hoverInfo.col != null)
                        _buildTooltip(
                          textTheme: textTheme,
                          colors: colors,
                          accent: accent,
                          hoverInfo: hoverInfo,
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

  _HoverInfo _calculateHoverInfo(double rowHeight) {
    int? hoverRow;
    int? hoverCol;
    double? hoverSpeed;
    String? turnType;

    if (_localPos != null && _boardSize != null) {
      final dy = _localPos!.dy;
      final dx = _localPos!.dx;

      if (dy >= 0 &&
          dy < _boardSize!.height &&
          dx >= 0 &&
          dx < _boardSize!.width) {
        hoverRow = (dy / rowHeight).floor();
        if (hoverRow >= 0 && hoverRow < widget.response.lapCount) {
          final colWidth = _boardSize!.width / widget.response.width;
          hoverCol = (dx / colWidth).floor();

          if (hoverCol >= 0 && hoverCol < widget.response.width) {
            hoverSpeed = widget.response.heatmap[hoverRow][hoverCol];
          }

          // 檢查轉身區域
          try {
            final mark = widget.response.marks.firstWhere(
              (m) => m.lapIndex == hoverRow! + 1,
            );
            final frac = dx / _boardSize!.width;

            if (mark.coneStartFrac != null && mark.coneEndFrac != null) {
              if (frac >= mark.coneStartFrac! && frac <= mark.coneEndFrac!) {
                turnType = 'Cone Turn';
              }
            }

            if (turnType == null &&
                mark.chairStartFrac != null &&
                mark.chairEndFrac != null) {
              if (frac >= mark.chairStartFrac! && frac <= mark.chairEndFrac!) {
                turnType = 'Chair Turn';
              }
            }
          } catch (_) {
            // 此圈無 mark
          }
        }
      }
    }

    return _HoverInfo(
      row: hoverRow,
      col: hoverCol,
      speed: hoverSpeed,
      turnType: turnType,
    );
  }

  Widget _buildLapLabels({
    required ColorScheme colors,
    required double rowHeight,
    required int? hoverRow,
  }) {
    return SizedBox(
      width: 84,
      child: Column(
        children: List.generate(widget.response.lapCount, (index) {
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
                fontWeight: isHoveringRow ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeatmapCanvas({
    required double availableWidth,
    required DashboardAccentColors accent,
    required ColorScheme colors,
    required int? hoverRow,
    required int? hoverCol,
  }) {
    return ClipRRect(
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
              painter: SpeedHeatmapPainter(
                heatmap: widget.response.heatmap,
                marks: {
                  for (final mark in widget.response.marks)
                    mark.lapIndex - 1: mark,
                },
                width: widget.response.width,
                scale: widget.scale,
                gridColor: context.dividerColor.withValues(alpha: 0.35),
                coneColor: accent.warning.withValues(alpha: 0.4),
                chairColor: accent.success.withValues(alpha: 0.4),
                backgroundColor:
                    colors.surfaceContainerHighest.withValues(alpha: 0.15),
                hoverRow: hoverRow,
                hoverCol: hoverCol,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTooltip({
    required TextTheme textTheme,
    required ColorScheme colors,
    required DashboardAccentColors accent,
    required _HoverInfo hoverInfo,
  }) {
    return Positioned(
      left: _localPos!.dx + 16,
      top: _localPos!.dy + 16,
      child: IgnorePointer(
        child: DashboardGlassTooltip(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lap ${hoverInfo.row! + 1}',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hoverInfo.speed?.toStringAsFixed(2) ?? '-',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [const ui.FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'm/s',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
              if (hoverInfo.turnType != null) ...[
                const SizedBox(height: 8),
                _buildTurnTypeBadge(accent, hoverInfo.turnType!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTurnTypeBadge(DashboardAccentColors accent, String turnType) {
    final isCone = turnType == 'Cone Turn';
    final color = isCone ? accent.warning : accent.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        turnType,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Hover 資訊封裝。
class _HoverInfo {
  const _HoverInfo({
    this.row,
    this.col,
    this.speed,
    this.turnType,
  });

  final int? row;
  final int? col;
  final double? speed;
  final String? turnType;
}
