import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:google_fonts/google_fonts.dart';

/// 線性刻度條。
///
/// 參考值在中間，使用者和族群位置用標記顯示。
/// 左邊表示數值較小，右邊表示數值較大。
///
/// 用於功能性評估卡片中，視覺化顯示使用者數值與參考值的相對位置。
class LinearScaleBar extends StatelessWidget {
  const LinearScaleBar({
    required this.metric,
    required this.statusColor,
    super.key,
  });

  final FunctionalMetric metric;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    // 計算刻度範圍：以參考值為中心，左右各延伸 50%
    final refValue = metric.referenceValue;
    final minValue = refValue * 0.5;
    final maxValue = refValue * 1.5;
    final range = maxValue - minValue;

    // 計算各點的位置（0~1）
    double normalizeValue(double value) {
      if (range <= 0) return 0.5;
      return ((value - minValue) / range).clamp(0.0, 1.0);
    }

    final userPos = normalizeValue(metric.userValue);
    const refPos = 0.5; // 參考值固定在中間
    final cohortValue = metric.cohortValue;
    final cohortPos = cohortValue != null ? normalizeValue(cohortValue) : null;

    // 判斷方向：越低越好時，左邊是好的
    final leftIsBetter = !metric.higherIsBetter;

    return Column(
      children: [
        // 刻度條
        SizedBox(
          height: 44,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // 背景軌道（漸層色）
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 18,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: leftIsBetter
                              ? [
                                  colors.tertiary.withValues(alpha: 0.25),
                                  colors.primary.withValues(alpha: 0.2),
                                  colors.error.withValues(alpha: 0.2),
                                ]
                              : [
                                  colors.error.withValues(alpha: 0.2),
                                  colors.primary.withValues(alpha: 0.2),
                                  colors.tertiary.withValues(alpha: 0.25),
                                ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 參考值區間帶（±10%）
                  Positioned(
                    left: width * 0.4,
                    top: 18,
                    width: width * 0.2,
                    height: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // 參考值標記線
                  Positioned(
                    left: width * refPos - 1,
                    top: 14,
                    child: Tooltip(
                      message: '參考值：${refValue.toStringAsFixed(2)}s',
                      child: Container(
                        width: 2,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colors.onSurface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),

                  // 族群標記（黃色菱形）
                  if (cohortPos != null && cohortValue != null)
                    Positioned(
                      left: (width * cohortPos - 6).clamp(0, width - 12),
                      top: 16,
                      child: Tooltip(
                        message: '族群：${cohortValue.toStringAsFixed(2)}s',
                        child: Transform.rotate(
                          angle: 0.785398,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.9),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 使用者標記（彩色圓形）
                  Positioned(
                    left: (width * userPos - 8).clamp(0, width - 16),
                    top: 10,
                    child: Tooltip(
                      message: '個人：${metric.userValue.toStringAsFixed(2)}s',
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 4),

        // 刻度標籤
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(metric.referenceValue * 0.5).toStringAsFixed(1)}s',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            Text(
              '${(metric.referenceValue * 1.5).toStringAsFixed(1)}s',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
