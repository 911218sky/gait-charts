import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/domain/utils/cohort_benchmark_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/shared/shared.dart';

/// 功能類別。
///
/// 用於分類功能評估指標，包含耐力、平衡、肌耐力三種類別。
enum FunctionalCategory {
  /// 耐力
  endurance,

  /// 平衡
  balance,

  /// 肌耐力
  muscleEndurance,
}

/// 功能分數項目。
///
/// 封裝單一功能評估指標的資料，包含 key、類別和指標數據。
/// 提供標籤、描述、圖示和顏色的便捷存取方法。
class FunctionalScoreItem {
  const FunctionalScoreItem({
    required this.key,
    required this.category,
    required this.metric,
  });

  final String key;
  final FunctionalCategory category;
  final FunctionalMetric metric;

  /// 取得指標的顯示標籤。
  String get label {
    return switch (key) {
      'walk_to_cone_s' => '走向角錐',
      'walk_back_and_sit_s' => '走回+坐下',
      'total_walking_s' => '總行走時間',
      'cone_turn_s' => '三角錐轉身',
      'stand_up_s' => '站起時間',
      'return_and_sit_s' => '走回+坐下',
      _ => key,
    };
  }

  /// 取得指標的簡短描述。
  String get shortDesc {
    return switch (key) {
      'walk_to_cone_s' => '行走體能',
      'walk_back_and_sit_s' => '整體體能',
      'total_walking_s' => '總時間',
      'cone_turn_s' => '平衡能力',
      'stand_up_s' => '下肢肌力',
      'return_and_sit_s' => '肌耐力',
      _ => '',
    };
  }

  /// 取得類別對應的圖示。
  IconData get categoryIcon {
    return switch (category) {
      FunctionalCategory.endurance => Icons.directions_walk_rounded,
      FunctionalCategory.balance => Icons.balance_rounded,
      FunctionalCategory.muscleEndurance => Icons.fitness_center_rounded,
    };
  }

  /// 取得類別對應的顏色。
  Color categoryColor(ColorScheme colors) {
    return switch (category) {
      FunctionalCategory.endurance => colors.primary,
      FunctionalCategory.balance => colors.tertiary,
      FunctionalCategory.muscleEndurance => Colors.orange,
    };
  }
}

/// 功能評估總覽摘要卡片。
///
/// 以直觀的「分數表」形式呈現功能評估結果，支援兩欄式佈局。
/// 顯示耐力、平衡、肌耐力三個類別的所有指標。
class FunctionalOverviewCard extends StatelessWidget {
  const FunctionalOverviewCard({
    required this.functional,
    required this.cohortName,
    super.key,
  });

  final FunctionalAssessment functional;
  final String cohortName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;

    // 收集所有指標
    final items = <FunctionalScoreItem>[];

    for (final entry in functional.endurance.entries) {
      items.add(FunctionalScoreItem(
        key: entry.key,
        category: FunctionalCategory.endurance,
        metric: entry.value,
      ));
    }

    for (final entry in functional.balance.entries) {
      items.add(FunctionalScoreItem(
        key: entry.key,
        category: FunctionalCategory.balance,
        metric: entry.value,
      ));
    }

    for (final entry in functional.muscleEndurance.entries) {
      items.add(FunctionalScoreItem(
        key: entry.key,
        category: FunctionalCategory.muscleEndurance,
        metric: entry.value,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    // 副標題：顯示族群名稱
    final subtitle = cohortName.isNotEmpty
        ? '與「$cohortName」研究參考值比較'
        : '與健康成人研究參考值比較';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF111111) : colors.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assessment_rounded,
                    size: 22,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '功能評估摘要',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // 圖例
                const ScoreLegend(),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          // 兩欄式分數表
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 寬度大於 500 時使用兩欄
                final useGrid = constraints.maxWidth > 500;

                if (useGrid) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: items.map((item) {
                      return SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: FunctionalScoreRow(item: item),
                      );
                    }).toList(),
                  );
                }

                // 窄螢幕使用單欄
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      FunctionalScoreRow(item: items[i]),
                      if (i < items.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 功能分數列（精簡分數卡片）。
///
/// 顯示單一功能評估指標的卡片，包含類別圖示、標籤、刻度條和數值。
class FunctionalScoreRow extends StatelessWidget {
  const FunctionalScoreRow({
    required this.item,
    super.key,
  });

  final FunctionalScoreItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final isDark = context.isDark;
    final palette = DashboardBenchmarkCompareColors.of(context);
    final metric = item.metric;

    final status = functionalStatus(metric);
    final statusColor = switch (status) {
      MetricComparisonStatus.similar => palette.inRange,
      MetricComparisonStatus.worse => palette.lower,
      MetricComparisonStatus.better => colors.tertiary,
    };

    final statusIcon = switch (status) {
      MetricComparisonStatus.similar => Icons.check_circle_rounded,
      MetricComparisonStatus.worse => Icons.warning_rounded,
      MetricComparisonStatus.better => Icons.star_rounded,
    };

    // 計算位置
    final refValue = metric.referenceValue;
    final userValue = metric.userValue;
    final minVal = refValue * 0.5;
    final maxVal = refValue * 1.5;
    final range = maxVal - minVal;
    final userPos =
        range > 0 ? ((userValue - minVal) / range).clamp(0.0, 1.0) : 0.5;
    final leftIsBetter = !metric.higherIsBetter;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.categoryColor(colors).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  item.categoryIcon,
                  size: 14,
                  color: item.categoryColor(colors),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      item.shortDesc,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // 狀態圖示
              Icon(statusIcon, size: 18, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          // 刻度條
          SizedBox(
            height: 32,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                // 計算族群值位置
                final cohortValue = metric.cohortValue;
                final cohortPos = cohortValue != null && range > 0
                    ? ((cohortValue - minVal) / range).clamp(0.0, 1.0)
                    : null;
                const cohortColor = Colors.amber;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 背景軌道
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 12,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: leftIsBetter
                                ? [
                                    colors.tertiary.withValues(alpha: 0.3),
                                    colors.primary.withValues(alpha: 0.3),
                                    colors.error.withValues(alpha: 0.25),
                                  ]
                                : [
                                    colors.error.withValues(alpha: 0.25),
                                    colors.primary.withValues(alpha: 0.3),
                                    colors.tertiary.withValues(alpha: 0.3),
                                  ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // 參考值標記（灰線）
                    Positioned(
                      left: width * 0.5 - 1,
                      top: 8,
                      child: Tooltip(
                        message: '參考值：${refValue.toStringAsFixed(2)}s',
                        child: Container(
                          width: 2,
                          height: 14,
                          decoration: BoxDecoration(
                            color: colors.onSurface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                    // 族群基準值標記（黃色菱形）
                    if (cohortPos != null && cohortValue != null)
                      Positioned(
                        left: (width * cohortPos - 5).clamp(0, width - 10),
                        top: 10,
                        child: Tooltip(
                          message: '族群：${cohortValue.toStringAsFixed(2)}s',
                          child: Transform.rotate(
                            angle: 0.785398, // 45 度
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: cohortColor,
                                borderRadius: BorderRadius.circular(1),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // 使用者標記（彩色圓形）
                    Positioned(
                      left: (width * userPos - 6).clamp(0, width - 12),
                      top: 0,
                      child: Tooltip(
                        message: '個人：${userValue.toStringAsFixed(2)}s',
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.4),
                                blurRadius: 4,
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
          const SizedBox(height: 8),
          // 數值列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 使用者數值
              RichText(
                text: TextSpan(
                  style: context.textTheme.labelMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(
                      text: userValue.toStringAsFixed(2),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: 's',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // 族群值（若有）
              if (metric.cohortValue != null)
                RichText(
                  text: TextSpan(
                    style: context.textTheme.labelSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    children: [
                      TextSpan(
                        text: '族群 ',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      TextSpan(
                        text: metric.cohortValue!.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      TextSpan(
                        text: 's',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              // 參考值
              Text(
                '參考 ${refValue.toStringAsFixed(2)}s',
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
