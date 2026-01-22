import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:google_fonts/google_fonts.dart';

/// 刻度條圖例說明。
///
/// 顯示使用者、參考值、族群的圖例項目，用於 [LinearScaleBar] 下方。
class ScaleBarLegend extends StatelessWidget {
  const ScaleBarLegend({
    required this.metric,
    required this.statusColor,
    super.key,
  });

  final FunctionalMetric metric;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        // 使用者
        LegendItem(
          marker: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          label: '使用者',
          value: '${metric.userValue.toStringAsFixed(2)}s',
          valueColor: statusColor,
        ),
        // 參考值
        LegendItem(
          marker: Container(
            width: 2,
            height: 12,
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          label: '參考值',
          value: '${metric.referenceValue.toStringAsFixed(2)}s',
          valueColor: colors.onSurface,
        ),
        // 族群（如果有）
        if (metric.cohortValue != null)
          LegendItem(
            marker: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            label: '族群',
            value: '${metric.cohortValue!.toStringAsFixed(2)}s',
            valueColor: colors.secondary,
          ),
      ],
    );
  }
}

/// 圖例項目。
///
/// 通用的圖例項目元件，包含標記、標籤和數值。
/// 用於 [ScaleBarLegend] 中顯示各種標記的說明。
class LegendItem extends StatelessWidget {
  const LegendItem({
    required this.marker,
    required this.label,
    required this.value,
    required this.valueColor,
    super.key,
  });

  final Widget marker;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 14, height: 14, child: Center(child: marker)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// 分數圖例。
///
/// 完整的圖例元件，顯示刻度條上各標記和狀態顏色的說明。
/// 用於功能評估摘要卡片的標題列。
class ScoreLegend extends StatelessWidget {
  const ScoreLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        // 標記說明
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendMarker(
              marker: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              label: '個人',
              color: colors.primary,
            ),
            const SizedBox(width: 12),
            _LegendMarker(
              marker: Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              label: '族群',
              color: Colors.amber,
            ),
          ],
        ),
        // 分隔線
        Container(
          width: 1,
          height: 14,
          color: colors.outlineVariant,
        ),
        // 狀態說明
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusDot(color: colors.tertiary, label: '優'),
            const SizedBox(width: 10),
            _StatusDot(color: colors.primary, label: '正常'),
            const SizedBox(width: 10),
            _StatusDot(
              color: colors.error.withValues(alpha: 0.85),
              label: '待加強',
            ),
          ],
        ),
      ],
    );
  }
}

/// 狀態圓點。
class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 圖例標記項目。
class _LegendMarker extends StatelessWidget {
  const _LegendMarker({
    required this.marker,
    required this.label,
    required this.color,
  });

  final Widget marker;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 12, height: 12, child: Center(child: marker)),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 圖例圓點。
///
/// 簡單的圓點加標籤組合，用於 [ScoreLegend] 中。
class LegendDot extends StatelessWidget {
  const LegendDot({
    required this.color,
    required this.label,
    super.key,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
