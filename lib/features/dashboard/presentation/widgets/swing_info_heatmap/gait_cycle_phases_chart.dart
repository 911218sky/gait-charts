import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/dashboard_overview.dart';
import 'package:google_fonts/google_fonts.dart';

/// 步態週期相位圖表。
///
/// 以水平條形圖顯示左右腳的步態週期相位分佈，
/// 包含雙支撐期 (DS)、單支撐期 (SS)、擺動期 (Swing)。
class GaitCyclePhasesChart extends StatelessWidget {
  const GaitCyclePhasesChart({
    required this.data,
    super.key,
  });

  final GaitCyclePhasesResponse data;

  // 左腳色系（藍色）
  static const _leftDsColor = Color(0xFF1E3A5F); // 深藍 - 雙支撐期
  static const _leftSsColor = Color(0xFF5B9BD5); // 中藍 - 單支撐期
  static const _leftSwingColor = Color(0xFFDEEBF7); // 淺藍 - 擺動期

  // 右腳色系（紅色）
  static const _rightDsColor = Color(0xFF8B0000); // 深紅 - 雙支撐期
  static const _rightSsColor = Color(0xFFE74C3C); // 中紅 - 單支撐期
  static const _rightSwingColor = Color(0xFFFADBD8); // 淺紅 - 擺動期

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
              Icons.timeline_rounded,
              color: colors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '平均步態週期',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '顯示左右腳各步態相位的時間分佈',
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
        // 左腳
        if (data.hasLeft) ...[
          _GaitCycleBar(
            label: 'Left',
            phaseData: data.left!,
            isLeft: true,
            offset: 0,
            rightOffset: data.rightOffsetPct ?? 0,
          ),
          const SizedBox(height: 16),
        ],
        // 右腳
        if (data.hasRight) ...[
          _GaitCycleBar(
            label: 'Right',
            phaseData: data.right!,
            isLeft: false,
            offset: data.rightOffsetPct ?? 0,
            rightOffset: data.rightOffsetPct ?? 0,
          ),
          const SizedBox(height: 24),
        ],
        // 圖例
        _Legend(hasLeft: data.hasLeft, hasRight: data.hasRight),
      ],
    );
  }
}

/// 單側步態週期條形圖。
class _GaitCycleBar extends StatelessWidget {
  const _GaitCycleBar({
    required this.label,
    required this.phaseData,
    required this.isLeft,
    required this.offset,
    required this.rightOffset,
  });

  final String label;
  final GaitPhaseData phaseData;
  final bool isLeft;
  final double offset;
  /// 右腳的 offset，用於計算整體縮放比例
  final double rightOffset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    // 根據左右腳決定繪製順序和顏色
    // 左腳：DS1 → SS → DS2 → Swing（從 0% 開始）
    // 右腳：Swing → DS1 → SS → DS2（從 offset 開始，讓 DS1 對齊左腳的 DS2）
    final phases = isLeft
        ? [
            _PhaseSegment(
              pct: phaseData.ds1Pct,
              color: GaitCyclePhasesChart._leftDsColor,
              label: 'DS1',
            ),
            _PhaseSegment(
              pct: phaseData.singleSupportPct,
              color: GaitCyclePhasesChart._leftSsColor,
              label: 'SS',
            ),
            _PhaseSegment(
              pct: phaseData.ds2Pct,
              color: GaitCyclePhasesChart._leftDsColor,
              label: 'DS2',
            ),
            _PhaseSegment(
              pct: phaseData.swingPct,
              color: GaitCyclePhasesChart._leftSwingColor,
              label: 'Swing',
            ),
          ]
        : [
            // 右腳：Swing → DS1 → SS → DS2
            // offset 會讓 Swing 結束後的 DS1 對齊左腳的 DS2
            _PhaseSegment(
              pct: phaseData.swingPct,
              color: GaitCyclePhasesChart._rightSwingColor,
              label: 'Swing',
            ),
            _PhaseSegment(
              pct: phaseData.ds1Pct,
              color: GaitCyclePhasesChart._rightDsColor,
              label: 'DS1',
            ),
            _PhaseSegment(
              pct: phaseData.singleSupportPct,
              color: GaitCyclePhasesChart._rightSsColor,
              label: 'SS',
            ),
            _PhaseSegment(
              pct: phaseData.ds2Pct,
              color: GaitCyclePhasesChart._rightDsColor,
              label: 'DS2',
            ),
          ];

    // 計算縮放比例：右腳會超出 offset%，所以整體需要縮小
    // 例如 offset = 10%，則總寬度變成 110%，需要縮放到 100%
    // 縮放比例 = 100 / (100 + offset)
    final scale = rightOffset > 0 ? 100 / (100 + rightOffset) : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 支撐期標註線（左腳在上方）
        if (isLeft) 
          _StanceBracket(
            stancePct: phaseData.stancePct, 
            isAbove: true,
            scale: scale,
          ),
        Row(
          children: [
            // 側別標籤
            SizedBox(
              width: 50,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ),
            // 條形圖
            Expanded(
              child: SizedBox(
                height: 44,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    // 應用縮放比例
                    final scaledWidth = totalWidth * scale;
                    // 右腳使用 offset 來對齊雙支撐期
                    final offsetWidth = isLeft ? 0.0 : scaledWidth * (offset / 100);

                    // 建立相位區塊列表
                    final children = <Widget>[];
                    
                    // 偏移空白（右腳用）
                    if (!isLeft && offset > 0) {
                      children.add(SizedBox(width: offsetWidth));
                    }
                    
                    // 各相位區塊 - 用 scaledWidth 計算，確保比例正確
                    for (final phase in phases) {
                      final segmentWidth = scaledWidth * (phase.pct / 100);
                      children.add(
                        Container(
                          width: segmentWidth,
                          height: 44,
                          decoration: BoxDecoration(
                            color: phase.color,
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: segmentWidth > 35
                                ? Text(
                                    '${phase.pct.round()}%',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getTextColor(phase.color),
                                      fontFeatures: const [
                                        ui.FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: children,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 週期時間
            SizedBox(
              width: 50,
              child: Text(
                '${phaseData.avgCycleTimeS.toStringAsFixed(2)}s',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        // 支撐期標註線（右腳在下方）
        if (!isLeft)
          _StanceBracket(
            stancePct: phaseData.stancePct,
            isAbove: false,
            offset: offset,
            swingPct: phaseData.swingPct,
            scale: scale,
          ),
      ],
    );
  }

  Color _getTextColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// 支撐期標註線。
class _StanceBracket extends StatelessWidget {
  const _StanceBracket({
    required this.stancePct,
    required this.isAbove,
    this.offset = 0,
    this.swingPct = 0,
    this.scale = 1.0,
  });

  final double stancePct;
  final bool isAbove;
  final double offset;
  final double swingPct;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: SizedBox(
        height: 20,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 扣除右側週期時間寬度，並應用縮放
            final totalWidth = (constraints.maxWidth - 58) * scale;
            
            // 左腳：從 0% 開始到 stance_pct%
            // 右腳：從 (offset + swing_pct)% 開始
            final startPct = isAbove ? 0.0 : (offset + swingPct);
            final startOffset = totalWidth * (startPct / 100);
            final bracketWidth = totalWidth * (stancePct / 100);

            return Stack(
              children: [
                Positioned(
                  left: startOffset,
                  width: bracketWidth,
                  top: isAbove ? 12 : 0,
                  bottom: isAbove ? 0 : 12,
                  child: CustomPaint(
                    painter: _BracketPainter(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                      isAbove: isAbove,
                    ),
                  ),
                ),
                Positioned(
                  left: startOffset + bracketWidth / 2 - 20,
                  top: isAbove ? 0 : 6,
                  child: Text(
                    '${stancePct.round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 繪製支撐期標註線的 Painter。
class _BracketPainter extends CustomPainter {
  const _BracketPainter({
    required this.color,
    required this.isAbove,
  });

  final Color color;
  final bool isAbove;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isAbove) {
      // 上方標註線：┌────────┐
      path.moveTo(0, size.height);
      path.lineTo(0, size.height - 4);
      path.lineTo(size.width, size.height - 4);
      path.lineTo(size.width, size.height);
    } else {
      // 下方標註線：└────────┘
      path.moveTo(0, 0);
      path.lineTo(0, 4);
      path.lineTo(size.width, 4);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BracketPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isAbove != isAbove;
  }
}

/// 相位區段資料。
class _PhaseSegment {
  const _PhaseSegment({
    required this.pct,
    required this.color,
    required this.label,
  });

  final double pct;
  final Color color;
  final String label;
}

/// 圖例。
class _Legend extends StatelessWidget {
  const _Legend({
    required this.hasLeft,
    required this.hasRight,
  });

  final bool hasLeft;
  final bool hasRight;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (hasLeft) ...[
          const _LegendItem(
            color: GaitCyclePhasesChart._leftDsColor,
            label: 'Left Double Support',
          ),
          const _LegendItem(
            color: GaitCyclePhasesChart._leftSsColor,
            label: 'Left Single Support',
          ),
          const _LegendItem(
            color: GaitCyclePhasesChart._leftSwingColor,
            label: 'Left Swing',
          ),
        ],
        if (hasRight) ...[
          const _LegendItem(
            color: GaitCyclePhasesChart._rightSsColor,
            label: 'Right Single Support',
          ),
          const _LegendItem(
            color: GaitCyclePhasesChart._rightDsColor,
            label: 'Right Double Support',
          ),
          const _LegendItem(
            color: GaitCyclePhasesChart._rightSwingColor,
            label: 'Right Swing',
          ),
        ],
      ],
    );
  }
}

/// 單個圖例項目。
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
