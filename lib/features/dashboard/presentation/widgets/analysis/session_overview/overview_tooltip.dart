import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';

/// Tooltip 狀態資料。
class OverviewTooltipState {
  OverviewTooltipState({
    required this.lapIndex,
    required this.totalSeconds,
    required this.ratioPct,
    required this.stages,
    required this.position,
    this.videoTimestampSeconds,
    this.isClockwise,
  });

  final int lapIndex;
  final double totalSeconds;
  final double ratioPct;
  final Map<String, double> stages;
  final Offset position;
  /// 此圈在影片中的起始時間（秒）
  final double? videoTimestampSeconds;
  /// 是否為順時鐘方向
  final bool? isClockwise;
}

/// 格式化秒數為 mm:ss 格式
String _formatVideoTime(double seconds) {
  final totalSec = seconds.round();
  final min = totalSec ~/ 60;
  final sec = totalSec % 60;
  return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

/// 圖表 Tooltip 內容。
class OverviewTooltipContent extends StatelessWidget {
  const OverviewTooltipContent({
    required this.lapIndex,
    required this.totalSeconds,
    required this.ratioPct,
    required this.stages,
    this.videoTimestampSeconds,
    this.isClockwise,
    this.onVideoSeek,
    super.key,
  });

  final int lapIndex;
  final double totalSeconds;
  final double ratioPct;
  final Map<String, double> stages;
  final double? videoTimestampSeconds;
  final bool? isClockwise;
  final VoidCallback? onVideoSeek;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lap $lapIndex',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (isClockwise != null) ...[
                const SizedBox(width: 8),
                Icon(
                  isClockwise! ? Icons.rotate_right : Icons.rotate_left,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  isClockwise! ? '順時鐘' : '逆時鐘',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '總耗時 ${totalSeconds.toStringAsFixed(2)} s',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '速度百分位 ${ratioPct.clamp(0, 100).toStringAsFixed(0)}%（越大越快）',
            style: TextStyle(
              color: colors.primary.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          // 影片時間
          if (videoTimestampSeconds != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 14, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '影片 ${_formatVideoTime(videoTimestampSeconds!)}',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (onVideoSeek != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onVideoSeek,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '跳轉',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (stages.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final entry in stages.entries.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${entry.key}: ${entry.value.toStringAsFixed(2)} s',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.72),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 6),
          Text(
            '點選可跳到細節',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
