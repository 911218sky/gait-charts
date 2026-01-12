import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_charts/app/theme.dart';
import 'package:gait_charts/core/widgets/async_request_view.dart';
import 'package:gait_charts/features/dashboard/domain/models/cohort_benchmark.dart';
import 'package:gait_charts/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cohort_list_item.dart';

/// 管理族群 Dialog
class ManageCohortsDialog extends ConsumerWidget {
  const ManageCohortsDialog({
    required this.onDeleteBenchmark,
    required this.onShowCohortUsers,
    super.key,
  });

  final void Function(String cohortName) onDeleteBenchmark;
  final void Function(String cohortName) onShowCohortUsers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colorScheme;
    final listAsync = ref.watch(cohortBenchmarkListProvider);

    return Dialog(
      backgroundColor: context.surfaceDeepest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, colors),
            _buildContent(context, ref, listAsync, colors),
            _buildFooter(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.groups_rounded,
              size: 20,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '管理族群',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '查看與管理已建立的 Cohort 基準',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colors.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<CohortBenchmarkListResponse> listAsync,
    ColorScheme colors,
  ) {
    return Flexible(
      child: AsyncRequestView<CohortBenchmarkListResponse>(
        requestId: 'manage_cohorts',
        value: listAsync,
        onRetry: () => ref.invalidate(cohortBenchmarkListProvider),
        dataBuilder: (context, data) {
          if (data.cohorts.isEmpty) {
            return _buildEmptyState(context, colors);
          }
          return _buildCohortList(context, data, colors);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceMedium,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.folder_off_rounded,
              size: 40,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '尚無族群基準',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '選擇 Cohort 並計算基準後會顯示在這裡',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCohortList(
    BuildContext context,
    CohortBenchmarkListResponse data,
    ColorScheme colors,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: data.cohorts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = data.cohorts[index];
        return CohortListItem(
          cohortName: item.cohortName,
          userCount: item.userCount,
          sessionCount: item.sessionCount,
          lapCount: item.lapCount,
          version: item.version,
          onTap: () => onShowCohortUsers(item.cohortName),
          onDelete: () {
            Navigator.pop(context);
            onDeleteBenchmark(item.cohortName);
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurface,
              side: BorderSide(color: colors.outlineVariant),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
}
