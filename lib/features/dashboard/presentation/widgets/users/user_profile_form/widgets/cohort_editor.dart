import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/users/user_profile_form/widgets/chips_editor.dart';

/// 族群標籤編輯器：顯示建議族群並支援自訂輸入。
class CohortEditor extends StatelessWidget {
  const CohortEditor({
    super.key,
    required this.labelStyle,
    required this.items,
    required this.onChanged,
    required this.cohortsAsync,
  });

  final TextStyle labelStyle;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final AsyncValue<UserCohortsResponse> cohortsAsync;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    final stats = cohortsAsync.maybeWhen(
      data: (r) => r.cohorts,
      orElse: () => const <UserCohortStat>[],
    );
    // 依使用人數排序，取前 12 個作為建議
    final suggested = [...stats]
      ..sort((a, b) => b.userCount.compareTo(a.userCount));
    final top = suggested.take(12).toList(growable: false);

    void addCohort(String label) {
      final v = label.trim();
      if (v.isEmpty) return;
      if (items.contains(v)) return;
      onChanged([...items, v]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipsEditor(
          label: '族群 (cohort)',
          labelStyle: labelStyle,
          hintText: '輸入後按 Enter 或「加入」',
          items: items,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: colors.onSurfaceVariant.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '可多選；若未指定，預設為「正常人」。',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
            ),
            if (cohortsAsync.isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        if (top.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in top)
                ActionChip(
                  onPressed: () => addCohort(s.cohort),
                  avatar: Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  label: Text('${s.cohort} (${s.userCount})'),
                ),
            ],
          ),
        ],
        if (cohortsAsync.hasError) ...[
          const SizedBox(height: 8),
          Text(
            '（族群清單載入失敗：${cohortsAsync.error}）',
            style: context.textTheme.bodySmall?.copyWith(color: colors.error),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
