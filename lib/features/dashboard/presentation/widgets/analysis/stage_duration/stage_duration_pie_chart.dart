import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/dashboard_glass_tooltip.dart';

/// 圓餅圖所需的資料。
class StagePieEntry {
  const StagePieEntry({
    required this.label,
    required this.seconds,
    required this.ratio,
    required this.color,
  });

  final String label;
  final double seconds;
  final double ratio;
  final Color color;

  StagePieEntry copyWith({
    String? label,
    double? seconds,
    double? ratio,
    Color? color,
  }) {
    return StagePieEntry(
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
    return other is StagePieEntry &&
        other.label == label &&
        other.seconds == seconds &&
        other.ratio == ratio &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(label, seconds, ratio, color);
}

/// 通用的階段占比圓餅圖組件。
class StageDurationPieChart extends StatefulWidget {
  const StageDurationPieChart({
    required this.entries,
    required this.centerLabel,
    required this.centerValue,
    super.key,
    this.title = '階段占比圓餅圖',
    this.subtitle = '觀察每個階段耗時佔整體的比例',
    this.height = 260,
    this.showLegend = true,
  });

  final List<StagePieEntry> entries;
  final String centerLabel;
  final String centerValue;
  final String title;
  final String subtitle;
  final double height;
  final bool showLegend;

  @override
  State<StageDurationPieChart> createState() => _StageDurationPieChartState();
}

class _StageDurationPieChartState extends State<StageDurationPieChart> {
  int? _touchedIndex;
  Offset? _touchPosition;

  // 只要其中一個節點有佔比即可繪製圓餅圖，否則顯示空狀態。
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
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
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
                '沒有可視化的階段資料',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 圓餅圖
              SizedBox(
                width: widget.height,
                height: widget.height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final chartSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final touchedEntry = _touchedIndex != null &&
                            _touchedIndex! >= 0 &&
                            _touchedIndex! < widget.entries.length
                        ? widget.entries[_touchedIndex!]
                        : null;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PieChart(
                          PieChartData(
                            centerSpaceColor: Colors.transparent,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection == null) {
                                  if (_touchedIndex != null) {
                                    setState(() {
                                      _touchedIndex = null;
                                      _touchPosition = null;
                                    });
                                  }
                                  return;
                                }
                                final newIndex =
                                    response.touchedSection!.touchedSectionIndex;
                                // -1 表示觸碰在 section 外
                                if (newIndex < 0 || newIndex >= widget.entries.length) {
                                  if (_touchedIndex != null) {
                                    setState(() {
                                      _touchedIndex = null;
                                      _touchPosition = null;
                                    });
                                  }
                                  return;
                                }
                                final localPos = event.localPosition;
                                // 只在 index 改變時更新
                                if (_touchedIndex != newIndex) {
                                  setState(() {
                                    _touchedIndex = newIndex;
                                    _touchPosition = localPos;
                                  });
                                }
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            sections: _buildSections(isDark),
                          ),
                        ),
                        // 中心文字
                        Positioned.fill(
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
                                  style: context.textTheme.titleMedium?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Tooltip
                        if (touchedEntry != null && _touchPosition != null)
                          Positioned(
                            left: (_touchPosition!.dx - 70).clamp(
                              0.0,
                              chartSize.width - 140,
                            ),
                            top: (_touchPosition!.dy - 80).clamp(
                              0.0,
                              chartSize.height - 100,
                            ),
                            child: IgnorePointer(
                              child: DashboardGlassTooltip(
                                child: _PieTooltipContent(entry: touchedEntry),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              // 圖例
              if (widget.showLegend) ...[
                const SizedBox(width: 24),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < widget.entries.length; i++)
                        _buildLegendItem(
                          context,
                          widget.entries[i],
                          i == _touchedIndex,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  List<PieChartSectionData> _buildSections(bool isDark) {
    return List.generate(widget.entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final entry = widget.entries[i];
      final radius = isTouched ? 50.0 : 45.0;
      final fontSize = isTouched ? 16.0 : 14.0;

      return PieChartSectionData(
        color: entry.color,
        value: entry.ratio * 100,
        title: '${(entry.ratio * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 2,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLegendItem(
    BuildContext context,
    StagePieEntry entry,
    bool isHighlighted,
  ) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted
            ? entry.color.withValues(alpha: isDark ? 0.15 : 0.1)
            : colors.onSurface.withValues(alpha: isDark ? 0.03 : 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? entry.color.withValues(alpha: 0.4)
              : colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.05),
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: entry.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            entry.label,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 11,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${entry.seconds.toStringAsFixed(1)}s · ${(entry.ratio * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// 圓餅圖 tooltip 內容。
class _PieTooltipContent extends StatelessWidget {
  const _PieTooltipContent({required this.entry});

  final StagePieEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Column(
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
                color: entry.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              entry.label,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${entry.seconds.toStringAsFixed(2)} 秒',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '佔比 ${(entry.ratio * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
