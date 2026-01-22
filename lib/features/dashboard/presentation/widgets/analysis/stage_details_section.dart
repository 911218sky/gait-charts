import 'package:flutter/material.dart';

import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';

/// 以表格呈現單圈的步態階段詳細資料。
class StageDetailsSection extends StatelessWidget {
  const StageDetailsSection({required this.lap, super.key});

  final LapSummary lap; // 單圈摘要

  /// 建立時間與距離統計容器
  Widget _buildStatsContainer(ColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.onSurface.withValues(alpha: isDark ? 0.2 : 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            _formatDuration(lap.totalDurationSeconds),
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'RobotoMono',
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 14,
            color: colors.onSurface.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 16),
          Icon(Icons.straighten, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '${lap.totalDistanceMeters.toStringAsFixed(2)} m',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final isNarrow = MediaQuery.sizeOf(context).width < 450;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 窄螢幕時垂直堆疊，寬螢幕時水平排列
            if (isNarrow) ...[
              Text(
                'Lap ${lap.lapIndex} 詳細資訊',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatsContainer(colors, isDark),
            ] else
              Row(
                children: [
                  Text(
                    'Lap ${lap.lapIndex} 詳細資訊',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _buildStatsContainer(colors, isDark),
                ],
              ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.8),
                1: FlexColumnWidth(1.6),
                2: FlexColumnWidth(2.4),
                3: FlexColumnWidth(1.6),
                4: FlexColumnWidth(2.4),
              },
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: colors.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
                ),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                const TableRow(
                  children: [
                    _HeaderCell(label: '階段', align: TextAlign.left),
                    _HeaderCell(label: '耗時 (秒)', align: TextAlign.right),
                    _HeaderCell(label: '耗時比例', align: TextAlign.left),
                    _HeaderCell(label: '距離 (公尺)', align: TextAlign.right),
                    _HeaderCell(label: '距離比例', align: TextAlign.left),
                  ],
                ),
                for (final stage in lap.stages)
                  TableRow(
                    children: [
                      _BodyCell(
                        stage.label,
                        // Walk to cone / Walk back 稍微突顯
                        style: (stage.label.toLowerCase().contains('walk'))
                            ? TextStyle(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w500,
                              )
                            : TextStyle(color: colors.onSurfaceVariant),
                      ),
                      _ValueCell(stage.durationSeconds.toStringAsFixed(2)),
                      _RatioCell(
                        value: stage.durationSeconds,
                        total: lap.totalDurationSeconds,
                        color: const Color(0xFF60A5FA), // Blue-400
                      ),
                      _ValueCell(
                        stage.distanceMeters != null
                            ? stage.distanceMeters!.toStringAsFixed(2)
                            : '-',
                      ),
                      _RatioCell(
                        value: stage.distanceMeters,
                        total: lap.totalDistanceMeters,
                        color: const Color(0xFF34D399), // Emerald-400
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 表頭樣式 cell。
class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, this.align = TextAlign.left});

  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        label,
        textAlign: align,
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 一般文字 cell (靠左)
class _BodyCell extends StatelessWidget {
  const _BodyCell(this.value, {this.style});

  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        value,
        style: style ?? TextStyle(color: colors.onSurfaceVariant),
      ),
    );
  }
}

/// 數值 cell (靠右，使用等寬數字)
class _ValueCell extends StatelessWidget {
  const _ValueCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: colors.onSurface,
          fontFamily: 'RobotoMono',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 比例視覺化 cell
class _RatioCell extends StatelessWidget {
  const _RatioCell({
    required this.value,
    required this.total,
    required this.color,
  });

  final double? value;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    if (value == null || total <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text('-', style: TextStyle(color: colors.onSurface.withValues(alpha: 0.3))),
      );
    }

    final ratio = (value! / total).clamp(0.0, 1.0);
    final percentText = '${(ratio * 100).toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            percentText,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: colors.onSurface.withValues(alpha: isDark ? 0.1 : 0.08),
              color: color,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 將秒數轉換為 mm:ss 文字。
String _formatDuration(double seconds) {
  if (seconds <= 0) {
    return '--';
  }
  final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toStringAsFixed(1).padLeft(4, '0');
  return '$minutes:$secs';
}
