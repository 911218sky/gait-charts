import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// 每分鐘趨勢圖：顯示速度與圈數的變化（分開兩個圖表）。
class MinutelyTrendChart extends StatelessWidget {
  const MinutelyTrendChart({
    required this.data,
    super.key,
  });

  final MinutelyTrendResponse data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              color: colors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '每分鐘趨勢分析',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '追蹤每分鐘的速度表現與完成圈數變化',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 速度圖表
        _SpeedChart(data: data),
        const SizedBox(height: 32),
        // 圈數圖表
        _LapCountChart(data: data),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tooltip 狀態
// ─────────────────────────────────────────────────────────────

class _TooltipState {
  _TooltipState({required this.index, required this.position});
  final int index;
  final Offset position;
}

// ─────────────────────────────────────────────────────────────
// 速度趨勢圖
// ─────────────────────────────────────────────────────────────

class _SpeedChart extends StatefulWidget {
  const _SpeedChart({required this.data});

  final MinutelyTrendResponse data;

  @override
  State<_SpeedChart> createState() => _SpeedChartState();
}

class _SpeedChartState extends State<_SpeedChart> {
  _TooltipState? _tooltip;

  @override
  void didUpdateWidget(covariant _SpeedChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 資料變更時清除 tooltip
    if (oldWidget.data != widget.data) {
      _tooltip = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final data = widget.data;

    final maxSpeed = data.avgSpeeds
        .whereType<double>()
        .fold<double>(0, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 小標題
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.speed_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '平均速度',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '單位：m/s',
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 圖表
        SizedBox(
          height: 200,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
              final tooltip = _tooltip;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  RepaintBoundary(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxSpeed > 0 ? maxSpeed / 4 : 0.25,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: colors.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 45,
                              interval: maxSpeed > 0 ? maxSpeed / 4 : 0.25,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: colors.primary.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= data.minutes.length) {
                                  return const SizedBox.shrink();
                                }
                                // 只在整數位置顯示標籤
                                if ((value - index).abs() > 0.01) {
                                  return const SizedBox.shrink();
                                }
                                final interval = _calculateXInterval(data.minutes.length);
                                if (index % interval != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Min ${data.minutes[index]}',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(color: colors.primary.withValues(alpha: 0.5), width: 2),
                            bottom: BorderSide(color: colors.outlineVariant, width: 1),
                          ),
                        ),
                        minX: 0,
                        maxX: (data.minutes.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxSpeed * 1.15,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _buildSpeedSpots(data),
                            isCurved: true,
                            curveSmoothness: 0.3,
                            color: colors.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 5,
                                  color: colors.primary,
                                  strokeWidth: 2,
                                  strokeColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  colors.primary.withValues(alpha: 0.3),
                                  colors.primary.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchSpotThreshold: 20,
                          handleBuiltInTouches: false,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipPadding: EdgeInsets.zero,
                            getTooltipItems: (spots) => spots
                                .map((_) => LineTooltipItem('', const TextStyle()))
                                .toList(),
                          ),
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.lineBarSpots == null ||
                                response.lineBarSpots!.isEmpty) {
                              if (_tooltip != null) {
                                setState(() => _tooltip = null);
                              }
                              return;
                            }
                            final spot = response.lineBarSpots!.first;
                            final newIndex = spot.x.toInt();
                            if (newIndex < 0 || newIndex >= data.minutes.length) {
                              if (_tooltip != null) {
                                setState(() => _tooltip = null);
                              }
                              return;
                            }
                            final localPos = event.localPosition ?? Offset.zero;
                            // 只在 index 改變時更新
                            if (_tooltip?.index != newIndex) {
                              setState(() {
                                _tooltip = _TooltipState(
                                  index: newIndex,
                                  position: localPos,
                                );
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  // Tooltip
                  if (tooltip != null && tooltip.index < data.minutes.length)
                    Positioned(
                      left: (tooltip.position.dx - 70).clamp(
                        0.0,
                        (chartSize.width - 140).clamp(0, double.infinity),
                      ),
                      top: (tooltip.position.dy - 90).clamp(
                        0.0,
                        (chartSize.height - 100).clamp(0, double.infinity),
                      ),
                      child: IgnorePointer(
                        child: DashboardGlassTooltip(
                          child: _SpeedTooltipContent(
                            minute: data.minutes[tooltip.index],
                            speed: data.avgSpeeds[tooltip.index],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<FlSpot> _buildSpeedSpots(MinutelyTrendResponse data) {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.avgSpeeds.length; i++) {
      final speed = data.avgSpeeds[i];
      if (speed != null && speed > 0) {
        spots.add(FlSpot(i.toDouble(), speed));
      }
    }
    return spots;
  }

  int _calculateXInterval(int length) {
    if (length <= 6) return 1;
    if (length <= 12) return 2;
    if (length <= 30) return 5;
    return 10;
  }
}

class _SpeedTooltipContent extends StatelessWidget {
  const _SpeedTooltipContent({
    required this.minute,
    required this.speed,
  });

  final int minute;
  final double? speed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '第$minute分鐘',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '速度 ${speed != null ? '${speed!.toStringAsFixed(3)} m/s' : '-'}',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.90),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 圈數趨勢圖
// ─────────────────────────────────────────────────────────────

class _LapCountChart extends StatefulWidget {
  const _LapCountChart({required this.data});

  final MinutelyTrendResponse data;

  @override
  State<_LapCountChart> createState() => _LapCountChartState();
}

class _LapCountChartState extends State<_LapCountChart> {
  _TooltipState? _tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final data = widget.data;

    final maxCount = data.lapCounts.fold<int>(0, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 小標題
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.repeat_rounded, size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Text(
                    '完成圈數',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '單位：圈/分鐘',
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 圖表
        SizedBox(
          height: 180,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
              final tooltip = _tooltip;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  RepaintBoundary(
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxCount > 0 ? (maxCount / 4).ceilToDouble() : 1,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: colors.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              interval: maxCount > 0 ? (maxCount / 4).ceilToDouble() : 1,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: Colors.orange.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= data.minutes.length) {
                                  return const SizedBox.shrink();
                                }
                                final interval = _calculateXInterval(data.minutes.length);
                                if (index % interval != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Min ${data.minutes[index]}',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(color: Colors.orange.withValues(alpha: 0.5), width: 2),
                            bottom: BorderSide(color: colors.outlineVariant, width: 1),
                          ),
                        ),
                        minY: 0,
                        maxY: (maxCount * 1.2).ceilToDouble(),
                        barGroups: _buildBarGroups(data, isDark),
                        barTouchData: BarTouchData(
                          enabled: true,
                          handleBuiltInTouches: false,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: EdgeInsets.zero,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                                BarTooltipItem('', const TextStyle()),
                          ),
                          touchCallback: (event, response) {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.spot == null) {
                              if (_tooltip != null) {
                                setState(() => _tooltip = null);
                              }
                              return;
                            }
                            final newIndex = response.spot!.touchedBarGroupIndex;
                            if (newIndex < 0 || newIndex >= data.minutes.length) {
                              if (_tooltip != null) {
                                setState(() => _tooltip = null);
                              }
                              return;
                            }
                            final localPos = event.localPosition ?? Offset.zero;
                            // 只在 index 改變或首次顯示時更新
                            if (_tooltip?.index != newIndex) {
                              setState(() {
                                _tooltip = _TooltipState(
                                  index: newIndex,
                                  position: localPos,
                                );
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  // Tooltip
                  if (tooltip != null && tooltip.index < data.minutes.length)
                    Positioned(
                      left: (tooltip.position.dx - 70).clamp(
                        0.0,
                        (chartSize.width - 140).clamp(0, double.infinity),
                      ),
                      top: (tooltip.position.dy - 100).clamp(
                        0.0,
                        (chartSize.height - 110).clamp(0, double.infinity),
                      ),
                      child: IgnorePointer(
                        child: DashboardGlassTooltip(
                          child: _LapCountTooltipContent(
                            minute: data.minutes[tooltip.index],
                            lapCount: data.lapCounts[tooltip.index],
                            lapDetails: data.lapDetails[tooltip.index],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups(MinutelyTrendResponse data, bool isDark) {
    return List.generate(data.lapCounts.length, (index) {
      final count = data.lapCounts[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.orange.withValues(alpha: 0.25),
                Colors.orange,
              ],
            ),
          ),
        ],
      );
    });
  }

  int _calculateXInterval(int length) {
    if (length <= 6) return 1;
    if (length <= 12) return 2;
    if (length <= 30) return 5;
    return 10;
  }
}

class _LapCountTooltipContent extends StatelessWidget {
  const _LapCountTooltipContent({
    required this.minute,
    required this.lapCount,
    required this.lapDetails,
  });

  final int minute;
  final int lapCount;
  final List<int> lapDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Min $minute',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '圈數 $lapCount 圈',
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (lapDetails.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '第 ${lapDetails.join(', ')} 圈',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.72),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
