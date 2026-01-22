import 'package:flutter/material.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/domain/utils/cohort_benchmark_utils.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/functional/functional_category_section.dart';

/// 功能性評估卡片（體能、平衡、肌耐力）。
///
/// 顯示使用者在各功能類別的評估結果，與健康成人研究參考值比較。
/// 使用 [FunctionalCategorySection] 呈現各類別的詳細指標。
class FunctionalAssessmentCard extends StatelessWidget {
  const FunctionalAssessmentCard({
    required this.functional,
    super.key,
  });

  final FunctionalAssessment functional;

  @override
  Widget build(BuildContext context) {
    if (!functional.hasData) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '功能性評估',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '與健康成人研究參考值比較，評估體能、平衡與肌耐力表現。',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (functional.endurance.isNotEmpty)
          FunctionalCategorySection(
            title: '體能（Endurance）',
            icon: Icons.directions_walk_rounded,
            description: '基於 6 分鐘步行測試研究',
            metrics: functional.endurance,
            order: enduranceOrder,
            labels: enduranceLabels,
          ),
        if (functional.balance.isNotEmpty) ...[
          const SizedBox(height: 20),
          FunctionalCategorySection(
            title: '平衡能力（Balance）',
            icon: Icons.balance_rounded,
            description: '基於 TUG 測試研究',
            metrics: functional.balance,
            order: balanceOrder,
            labels: balanceLabels,
          ),
        ],
        if (functional.muscleEndurance.isNotEmpty) ...[
          const SizedBox(height: 20),
          FunctionalCategorySection(
            title: '肌耐力（Muscle Endurance）',
            icon: Icons.fitness_center_rounded,
            description: '基於 TUG 測試研究',
            metrics: functional.muscleEndurance,
            order: muscleEnduranceOrder,
            labels: muscleEnduranceLabels,
          ),
        ],
      ],
    );
  }
}
