import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/features/dashboard/domain/models/user_profile.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/cohort_benchmark/cohort_selector_dialog.dart';
import 'package:gait_charts/features/dashboard/presentation/widgets/shared/fields/session_autocomplete_field.dart';
import 'package:google_fonts/google_fonts.dart';

/// 族群基準分析的設定區塊。
class CohortConfigurationSection extends ConsumerWidget {
  const CohortConfigurationSection({
    required this.selectedCohortName,
    required this.sessionController,
    required this.isCalculating,
    required this.compareIsLoading,
    required this.hasSelectedCohort,
    required this.onCohortChanged,
    required this.onCalculate,
    required this.onCompare,
    required this.onBrowseSessions,
    required this.onManageCohorts,
    super.key,
  });

  final String? selectedCohortName;
  final TextEditingController sessionController;
  final bool isCalculating;
  final bool compareIsLoading;
  final bool hasSelectedCohort;
  final ValueChanged<String?> onCohortChanged;
  final void Function(bool force) onCalculate;
  final VoidCallback onCompare;
  final VoidCallback onBrowseSessions;
  final VoidCallback onManageCohorts;

  Future<void> _selectCohort(BuildContext context) async {
    final selected = await CohortSelectorDialog.show(
      context,
      initialSelected: selectedCohortName,
    );
    if (selected != null && selected.trim().isNotEmpty) {
      onCohortChanged(selected.trim());
      // 選擇後自動觸發計算
      onCalculate(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;


    // 取得選中 cohort 的使用者數量（用於顯示）
    final cohortsAsync = ref.watch(userCohortsProvider(false));
    final selectedCohortStat = cohortsAsync.maybeWhen(
      data: (r) => r.cohorts.firstWhere(
        (c) => c.cohort == selectedCohortName,
        orElse: () => const UserCohortStat(cohort: '', userCount: 0),
      ),
      orElse: () => const UserCohortStat(cohort: '', userCount: 0),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceDeepest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCohortRow(context, colors, selectedCohortStat),
          const SizedBox(height: 16),
          _buildSessionRow(context, colors),
        ],
      ),
    );
  }

  Widget _buildCohortRow(
    BuildContext context,
    ColorScheme colors,
    UserCohortStat selectedCohortStat,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '基準族群 (Cohort)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _buildCohortSelector(context, colors, selectedCohortStat),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildActionButtons(context, colors),
      ],
    );
  }

  Widget _buildCohortSelector(
    BuildContext context,
    ColorScheme colors,
    UserCohortStat selectedCohortStat,
  ) {
    return InkWell(
      onTap: isCalculating ? null : () => _selectCohort(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasSelectedCohort
                ? colors.primary.withValues(alpha: 0.4)
                : colors.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.surfaceMedium,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 16,
                color: hasSelectedCohort
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasSelectedCohort
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedCohortName!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        if (selectedCohortStat.userCount > 0)
                          Text(
                            '${selectedCohortStat.userCount} 人',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    )
                  : Text(
                      '點擊選擇族群...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
            ),
            Icon(
              Icons.unfold_more_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildActionButtons(BuildContext context, ColorScheme colors) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onManageCohorts,
          icon: const Icon(Icons.settings_outlined, size: 16),
          label: const Text('管理'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            side: BorderSide(color: colors.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: hasSelectedCohort && !isCalculating
              ? () => onCalculate(true)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: context.surfaceMedium,
            foregroundColor: colors.onSurface,
            disabledBackgroundColor: context.surfaceDark,
            disabledForegroundColor: colors.onSurface.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: isCalculating
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('重新計算'),
        ),
      ],
    );
  }

  Widget _buildSessionRow(BuildContext context, ColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: SessionAutocompleteField(
            controller: sessionController,
            labelText: '比對 Session',
            hintText: '輸入 session_name',
            onSubmitted: (_) => onCompare(),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onBrowseSessions,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            side: BorderSide(color: colors.outlineVariant),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Icon(Icons.list, size: 20),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: compareIsLoading ? null : onCompare,
          icon: compareIsLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_forward, size: 18),
          label: const Text('開始分析'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
